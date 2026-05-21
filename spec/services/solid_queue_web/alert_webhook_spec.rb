require "rails_helper"

RSpec.describe SolidQueueWeb::AlertWebhook do
  let(:webhook_url) { "http://example.com/webhook" }

  before do
    SolidQueueWeb.alert_webhook_url       = webhook_url
    SolidQueueWeb.alert_failure_threshold = 5
    SolidQueueWeb.alert_webhook_cooldown  = 3600
    allow(Thread).to receive(:new).and_yield
    allow_any_instance_of(Net::HTTP).to receive(:request).and_return(Net::HTTPSuccess.new("1.1", "200", "OK"))
  end

  after do
    SolidQueueWeb.alert_webhook_url       = nil
    SolidQueueWeb.alert_failure_threshold = nil
    SolidQueueWeb.alert_webhook_cooldown  = nil
    described_class.reset!
  end

  describe ".call" do
    it "fires when failure count meets the threshold" do
      expect_any_instance_of(Net::HTTP).to receive(:request)
      described_class.call(failure_count: 5)
    end

    it "fires when failure count exceeds the threshold" do
      expect_any_instance_of(Net::HTTP).to receive(:request)
      described_class.call(failure_count: 10)
    end

    it "does not fire when failure count is below threshold" do
      expect_any_instance_of(Net::HTTP).not_to receive(:request)
      described_class.call(failure_count: 4)
    end

    it "does not fire when webhook url is not configured" do
      SolidQueueWeb.alert_webhook_url = nil
      expect_any_instance_of(Net::HTTP).not_to receive(:request)
      described_class.call(failure_count: 10)
    end

    it "does not fire when threshold is not configured" do
      SolidQueueWeb.alert_failure_threshold = nil
      expect_any_instance_of(Net::HTTP).not_to receive(:request)
      described_class.call(failure_count: 10)
    end

    it "does not fire again within the cooldown window" do
      described_class.call(failure_count: 5)
      expect_any_instance_of(Net::HTTP).not_to receive(:request)
      described_class.call(failure_count: 5)
    end

    it "fires again after the cooldown window expires" do
      described_class.call(failure_count: 5)
      described_class.instance_variable_set(:@last_fired_at, 2.hours.ago)
      expect_any_instance_of(Net::HTTP).to receive(:request)
      described_class.call(failure_count: 5)
    end

    it "posts to the configured URL" do
      uri = URI.parse(webhook_url)
      expect(Net::HTTP).to receive(:new).with(uri.host, uri.port).and_call_original
      described_class.call(failure_count: 5)
    end

    it "sends a JSON payload with event, failure_count, threshold, and fired_at" do
      posted_body = nil
      allow_any_instance_of(Net::HTTP).to receive(:request) do |_, req|
        posted_body = JSON.parse(req.body)
        Net::HTTPSuccess.new("1.1", "200", "OK")
      end

      described_class.call(failure_count: 7)

      expect(posted_body["event"]).to eq("failure_threshold_exceeded")
      expect(posted_body["failure_count"]).to eq(7)
      expect(posted_body["threshold"]).to eq(5)
      expect(posted_body["fired_at"]).to be_present
    end

    it "sets Content-Type to application/json" do
      sent_request = nil
      allow_any_instance_of(Net::HTTP).to receive(:request) do |_, req|
        sent_request = req
        Net::HTTPSuccess.new("1.1", "200", "OK")
      end

      described_class.call(failure_count: 5)

      expect(sent_request["Content-Type"]).to eq("application/json")
    end

    it "logs an error and does not raise when the HTTP request fails" do
      allow_any_instance_of(Net::HTTP).to receive(:request).and_raise(RuntimeError, "connection refused")
      expect(Rails.logger).to receive(:error).with(/Alert webhook failed/)
      expect { described_class.call(failure_count: 5) }.not_to raise_error
    end

    context "when alert_webhook_url is an array" do
      let(:second_url) { "http://example.com/second-webhook" }

      before { SolidQueueWeb.alert_webhook_url = [webhook_url, second_url] }

      it "posts to all configured URLs" do
        expect(Net::HTTP).to receive(:new).twice.and_call_original
        described_class.call(failure_count: 5)
      end

      it "continues posting to remaining URLs when one fails" do
        call_count = 0
        allow_any_instance_of(Net::HTTP).to receive(:request) do
          call_count += 1
          raise RuntimeError, "connection refused" if call_count == 1
          Net::HTTPSuccess.new("1.1", "200", "OK")
        end
        allow(Rails.logger).to receive(:error)
        expect { described_class.call(failure_count: 5) }.not_to raise_error
        expect(call_count).to eq(2)
      end

      it "is not configured when the array is empty" do
        SolidQueueWeb.alert_webhook_url = []
        expect_any_instance_of(Net::HTTP).not_to receive(:request)
        described_class.call(failure_count: 10)
      end
    end
  end
end
