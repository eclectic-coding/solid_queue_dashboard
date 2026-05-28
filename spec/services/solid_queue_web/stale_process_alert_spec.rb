require "rails_helper"

RSpec.describe SolidQueueWeb::StaleProcessAlert do
  let(:webhook_url) { "http://example.com/webhook" }

  before do
    SolidQueueWeb.alert_webhook_url             = webhook_url
    SolidQueueWeb.alert_stale_process_threshold = 1
    SolidQueueWeb.alert_webhook_cooldown        = 3600
    allow(Thread).to receive(:new).and_yield
    allow_any_instance_of(Net::HTTP).to receive(:request).and_return(Net::HTTPSuccess.new("1.1", "200", "OK"))
  end

  after do
    SolidQueueWeb.alert_webhook_url             = nil
    SolidQueueWeb.alert_stale_process_threshold = nil
    SolidQueueWeb.alert_webhook_cooldown        = nil
    described_class.reset!
  end

  def create_process(stale: false)
    heartbeat = stale ? (SolidQueue.process_alive_threshold + 1.minute).ago : 30.seconds.ago
    SolidQueue::Process.create!(
      kind: "Worker", pid: rand(10_000..99_999), hostname: "test-host",
      name: "worker-#{SecureRandom.hex(4)}", last_heartbeat_at: heartbeat
    )
  end

  describe ".call" do
    it "fires when stale process count meets the threshold" do
      create_process(stale: true)
      expect_any_instance_of(Net::HTTP).to receive(:request)
      described_class.call
    end

    it "fires when stale process count exceeds the threshold" do
      3.times { create_process(stale: true) }
      expect_any_instance_of(Net::HTTP).to receive(:request)
      described_class.call
    end

    it "does not fire when stale process count is below the threshold" do
      SolidQueueWeb.alert_stale_process_threshold = 2
      create_process(stale: true)
      expect_any_instance_of(Net::HTTP).not_to receive(:request)
      described_class.call
    end

    it "does not count healthy processes as stale" do
      create_process(stale: false)
      expect_any_instance_of(Net::HTTP).not_to receive(:request)
      described_class.call
    end

    it "does not fire when alert_stale_process_threshold is not configured" do
      SolidQueueWeb.alert_stale_process_threshold = nil
      create_process(stale: true)
      expect_any_instance_of(Net::HTTP).not_to receive(:request)
      described_class.call
    end

    it "does not fire when webhook url is not configured" do
      SolidQueueWeb.alert_webhook_url = nil
      create_process(stale: true)
      expect_any_instance_of(Net::HTTP).not_to receive(:request)
      described_class.call
    end

    it "does not fire when no processes exist" do
      expect_any_instance_of(Net::HTTP).not_to receive(:request)
      described_class.call
    end

    it "does not fire again within the cooldown window" do
      create_process(stale: true)
      described_class.call
      expect_any_instance_of(Net::HTTP).not_to receive(:request)
      described_class.call
    end

    it "fires again after the cooldown window expires" do
      create_process(stale: true)
      described_class.call
      described_class.instance_variable_set(:@last_fired_at, 2.hours.ago)
      expect_any_instance_of(Net::HTTP).to receive(:request)
      described_class.call
    end

    it "sends a JSON payload with the correct fields" do
      2.times { create_process(stale: true) }
      posted_body = nil
      allow_any_instance_of(Net::HTTP).to receive(:request) do |_, req|
        posted_body = JSON.parse(req.body)
        Net::HTTPSuccess.new("1.1", "200", "OK")
      end

      described_class.call

      expect(posted_body["event"]).to eq("stale_process_detected")
      expect(posted_body["stale_process_count"]).to eq(2)
      expect(posted_body["threshold"]).to eq(1)
      expect(posted_body["fired_at"]).to be_present
    end

    it "sets Content-Type to application/json" do
      create_process(stale: true)
      sent_request = nil
      allow_any_instance_of(Net::HTTP).to receive(:request) do |_, req|
        sent_request = req
        Net::HTTPSuccess.new("1.1", "200", "OK")
      end

      described_class.call

      expect(sent_request["Content-Type"]).to eq("application/json")
    end

    it "logs an error and does not raise when the HTTP request fails" do
      create_process(stale: true)
      allow_any_instance_of(Net::HTTP).to receive(:request).and_raise(RuntimeError, "connection refused")
      expect(Rails.logger).to receive(:error).with(/Stale process alert webhook failed/)
      expect { described_class.call }.not_to raise_error
    end

    context "when alert_webhook_url is an array" do
      let(:second_url) { "http://example.com/second-webhook" }

      before { SolidQueueWeb.alert_webhook_url = [webhook_url, second_url] }

      it "posts to all configured URLs" do
        create_process(stale: true)
        expect(Net::HTTP).to receive(:new).twice.and_call_original
        described_class.call
      end
    end
  end
end
