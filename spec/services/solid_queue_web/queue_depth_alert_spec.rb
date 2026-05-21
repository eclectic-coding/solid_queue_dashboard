require "rails_helper"

RSpec.describe SolidQueueWeb::QueueDepthAlert do
  let(:webhook_url) { "http://example.com/webhook" }

  before do
    SolidQueueWeb.alert_webhook_url      = webhook_url
    SolidQueueWeb.alert_queue_thresholds = { "critical" => 5 }
    SolidQueueWeb.alert_webhook_cooldown = 3600
    allow(Thread).to receive(:new).and_yield
    allow_any_instance_of(Net::HTTP).to receive(:request).and_return(Net::HTTPSuccess.new("1.1", "200", "OK"))
  end

  after do
    SolidQueueWeb.alert_webhook_url      = nil
    SolidQueueWeb.alert_queue_thresholds = nil
    SolidQueueWeb.alert_webhook_cooldown = nil
    described_class.reset!
  end

  def enqueue(queue_name:, count:)
    count.times do
      job = SolidQueue::Job.create!(
        queue_name: queue_name,
        class_name: "TestJob",
        arguments:  {},
        active_job_id: SecureRandom.uuid
      )
      job.ready_execution
    end
  end

  describe ".call" do
    it "fires when a queue's ready count meets the threshold" do
      enqueue(queue_name: "critical", count: 5)
      expect_any_instance_of(Net::HTTP).to receive(:request)
      described_class.call
    end

    it "fires when a queue's ready count exceeds the threshold" do
      enqueue(queue_name: "critical", count: 10)
      expect_any_instance_of(Net::HTTP).to receive(:request)
      described_class.call
    end

    it "does not fire when ready count is below the threshold" do
      enqueue(queue_name: "critical", count: 4)
      expect_any_instance_of(Net::HTTP).not_to receive(:request)
      described_class.call
    end

    it "does not fire for queues without a configured threshold" do
      enqueue(queue_name: "default", count: 100)
      expect_any_instance_of(Net::HTTP).not_to receive(:request)
      described_class.call
    end

    it "does not fire when alert_queue_thresholds is empty" do
      SolidQueueWeb.alert_queue_thresholds = {}
      enqueue(queue_name: "critical", count: 10)
      expect_any_instance_of(Net::HTTP).not_to receive(:request)
      described_class.call
    end

    it "does not fire when no webhook URL is configured" do
      SolidQueueWeb.alert_webhook_url = nil
      enqueue(queue_name: "critical", count: 10)
      expect_any_instance_of(Net::HTTP).not_to receive(:request)
      described_class.call
    end

    it "fires independently per queue" do
      SolidQueueWeb.alert_queue_thresholds = { "critical" => 5, "default" => 10 }
      enqueue(queue_name: "critical", count: 5)
      enqueue(queue_name: "default", count: 3)
      expect(Net::HTTP).to receive(:new).once.and_call_original
      described_class.call
    end

    it "does not fire again within the cooldown window" do
      enqueue(queue_name: "critical", count: 5)
      described_class.call
      expect_any_instance_of(Net::HTTP).not_to receive(:request)
      described_class.call
    end

    it "fires again after the cooldown window expires" do
      enqueue(queue_name: "critical", count: 5)
      described_class.call
      described_class.instance_variable_get(:@last_fired_at)["critical"] = 2.hours.ago
      expect_any_instance_of(Net::HTTP).to receive(:request)
      described_class.call
    end

    it "tracks cooldown independently per queue" do
      SolidQueueWeb.alert_queue_thresholds = { "critical" => 5, "default" => 5 }
      enqueue(queue_name: "critical", count: 5)
      enqueue(queue_name: "default", count: 5)
      described_class.call
      described_class.instance_variable_get(:@last_fired_at)["critical"] = 2.hours.ago
      expect(Net::HTTP).to receive(:new).once.and_call_original
      described_class.call
    end

    it "sends a JSON payload with the correct fields" do
      enqueue(queue_name: "critical", count: 5)
      posted_body = nil
      allow_any_instance_of(Net::HTTP).to receive(:request) do |_, req|
        posted_body = JSON.parse(req.body)
        Net::HTTPSuccess.new("1.1", "200", "OK")
      end

      described_class.call

      expect(posted_body["event"]).to eq("queue_depth_threshold_exceeded")
      expect(posted_body["queue_name"]).to eq("critical")
      expect(posted_body["depth"]).to eq(5)
      expect(posted_body["threshold"]).to eq(5)
      expect(posted_body["fired_at"]).to be_present
    end

    it "logs an error and does not raise when the HTTP request fails" do
      enqueue(queue_name: "critical", count: 5)
      allow_any_instance_of(Net::HTTP).to receive(:request).and_raise(RuntimeError, "connection refused")
      expect(Rails.logger).to receive(:error).with(/Queue depth alert webhook failed/)
      expect { described_class.call }.not_to raise_error
    end
  end
end
