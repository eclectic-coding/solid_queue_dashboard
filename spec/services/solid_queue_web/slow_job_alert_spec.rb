require "rails_helper"

RSpec.describe SolidQueueWeb::SlowJobAlert do
  let(:webhook_url) { "http://example.com/webhook" }

  before do
    SolidQueueWeb.alert_webhook_url              = webhook_url
    SolidQueueWeb.slow_job_threshold             = 5.minutes
    SolidQueueWeb.alert_slow_job_count_threshold = 3
    SolidQueueWeb.alert_webhook_cooldown         = 3600
    allow(Thread).to receive(:new).and_yield
    allow_any_instance_of(Net::HTTP).to receive(:request).and_return(Net::HTTPSuccess.new("1.1", "200", "OK"))
  end

  after do
    SolidQueueWeb.alert_webhook_url              = nil
    SolidQueueWeb.slow_job_threshold             = nil
    SolidQueueWeb.alert_slow_job_count_threshold = nil
    SolidQueueWeb.alert_webhook_cooldown         = nil
    described_class.reset!
  end

  let(:worker_process) do
    SolidQueue::Process.create!(
      kind: "Worker", pid: 99_999, hostname: "test-host",
      name: "worker-slow-alert-test", last_heartbeat_at: Time.current
    )
  end

  def create_slow_claimed_job(count: 1)
    count.times do |i|
      job = SolidQueue::Job.create!(
        queue_name:    "default",
        class_name:    "SlowTestJob",
        arguments:     {},
        active_job_id: SecureRandom.uuid
      )
      execution = SolidQueue::ClaimedExecution.create!(job: job, process: worker_process)
      execution.update_columns(created_at: 10.minutes.ago)
    end
  end

  describe ".call" do
    it "fires when slow job count meets the threshold" do
      create_slow_claimed_job(count: 3)
      expect_any_instance_of(Net::HTTP).to receive(:request)
      described_class.call
    end

    it "fires when slow job count exceeds the threshold" do
      create_slow_claimed_job(count: 5)
      expect_any_instance_of(Net::HTTP).to receive(:request)
      described_class.call
    end

    it "does not fire when slow job count is below the threshold" do
      create_slow_claimed_job(count: 2)
      expect_any_instance_of(Net::HTTP).not_to receive(:request)
      described_class.call
    end

    it "does not count jobs that are not yet slow" do
      job = SolidQueue::Job.create!(
        queue_name:    "default",
        class_name:    "FastTestJob",
        arguments:     {},
        active_job_id: SecureRandom.uuid
      )
      execution = SolidQueue::ClaimedExecution.create!(job: job, process: worker_process)
      execution.update_columns(created_at: 1.minute.ago)

      expect_any_instance_of(Net::HTTP).not_to receive(:request)
      described_class.call
    end

    it "does not fire when slow_job_threshold is not configured" do
      SolidQueueWeb.slow_job_threshold = nil
      create_slow_claimed_job(count: 5)
      expect_any_instance_of(Net::HTTP).not_to receive(:request)
      described_class.call
    end

    it "does not fire when alert_slow_job_count_threshold is not configured" do
      SolidQueueWeb.alert_slow_job_count_threshold = nil
      create_slow_claimed_job(count: 5)
      expect_any_instance_of(Net::HTTP).not_to receive(:request)
      described_class.call
    end

    it "does not fire when webhook url is not configured" do
      SolidQueueWeb.alert_webhook_url = nil
      create_slow_claimed_job(count: 5)
      expect_any_instance_of(Net::HTTP).not_to receive(:request)
      described_class.call
    end

    it "does not fire again within the cooldown window" do
      create_slow_claimed_job(count: 3)
      described_class.call
      expect_any_instance_of(Net::HTTP).not_to receive(:request)
      described_class.call
    end

    it "fires again after the cooldown window expires" do
      create_slow_claimed_job(count: 3)
      described_class.call
      described_class.instance_variable_set(:@last_fired_at, 2.hours.ago)
      expect_any_instance_of(Net::HTTP).to receive(:request)
      described_class.call
    end

    it "sends a JSON payload with the correct fields" do
      create_slow_claimed_job(count: 4)
      posted_body = nil
      allow_any_instance_of(Net::HTTP).to receive(:request) do |_, req|
        posted_body = JSON.parse(req.body)
        Net::HTTPSuccess.new("1.1", "200", "OK")
      end

      described_class.call

      expect(posted_body["event"]).to eq("slow_job_threshold_exceeded")
      expect(posted_body["slow_job_count"]).to eq(4)
      expect(posted_body["threshold"]).to eq(3)
      expect(posted_body["fired_at"]).to be_present
    end

    it "sets Content-Type to application/json" do
      create_slow_claimed_job(count: 3)
      sent_request = nil
      allow_any_instance_of(Net::HTTP).to receive(:request) do |_, req|
        sent_request = req
        Net::HTTPSuccess.new("1.1", "200", "OK")
      end

      described_class.call

      expect(sent_request["Content-Type"]).to eq("application/json")
    end

    it "logs an error and does not raise when the HTTP request fails" do
      create_slow_claimed_job(count: 3)
      allow_any_instance_of(Net::HTTP).to receive(:request).and_raise(RuntimeError, "connection refused")
      expect(Rails.logger).to receive(:error).with(/Slow job alert webhook failed/)
      expect { described_class.call }.not_to raise_error
    end

    context "when alert_webhook_url is an array" do
      let(:second_url) { "http://example.com/second-webhook" }

      before { SolidQueueWeb.alert_webhook_url = [webhook_url, second_url] }

      it "posts to all configured URLs" do
        create_slow_claimed_job(count: 3)
        expect(Net::HTTP).to receive(:new).twice.and_call_original
        described_class.call
      end
    end
  end
end
