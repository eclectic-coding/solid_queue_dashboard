require "rails_helper"

RSpec.describe "Dashboard", type: :request do
  describe "GET /jobs" do
    it "returns HTTP success" do
      get "/jobs"
      expect(response).to have_http_status(:ok), -> { response.body }
    end

    it "displays the dashboard heading" do
      get "/jobs"
      expect(response.body).to include("Dashboard")
    end

    it "includes a recurring tasks stat card and quick link" do
      SolidQueue::RecurringTask.create!(key: "t", schedule: "* * * * *", command: "echo hi")
      get "/jobs"
      expect(response.body).to include("Recurring")
      expect(response.body).to include("recurring_tasks")
    end

    it "shows Done (1h) and Done (24h) stat cards" do
      get "/jobs"
      expect(response.body).to include("Done (1h)")
      expect(response.body).to include("Done (24h)")
    end

    it "renders the throughput card with completed job counts" do
      job = SolidQueue::Job.new(
        queue_name: "default", class_name: "TestJob",
        arguments: {}.to_json, priority: 0, active_job_id: SecureRandom.uuid
      )
      job.finished_at = 30.minutes.ago
      job.created_at = 35.minutes.ago
      job.updated_at = 30.minutes.ago
      job.save!(validate: false)

      get "/jobs"
      expect(response.body).to include("Throughput")
      expect(response.body).to include("sqd-sparkline")
    end

    it "shows empty-state message when no jobs have finished" do
      get "/jobs"
      expect(response.body).to include("No completed jobs in the last 24 hours")
    end
  end

  describe "slow jobs card" do
    after { SolidQueueWeb.slow_job_threshold = nil }

    it "shows the slow jobs card when threshold is set and jobs exceed it" do
      process = SolidQueue::Process.create!(
        kind: "Worker", pid: 99_998, hostname: "test-host",
        name: "worker-slow-test", last_heartbeat_at: Time.current
      )
      job = SolidQueue::Job.create!(
        queue_name: "default", class_name: "SlowJob",
        arguments: {}, active_job_id: SecureRandom.uuid
      )
      execution = SolidQueue::ClaimedExecution.create!(job: job, process: process)
      execution.update_columns(created_at: 10.minutes.ago)
      SolidQueueWeb.slow_job_threshold = 1.second

      get "/jobs"
      expect(response.body).to include("Slow Jobs")
    end

    it "does not show the slow jobs card when threshold is not configured" do
      get "/jobs"
      expect(response.body).not_to include("Slow Jobs")
    end

    it "does not show the slow jobs card when no jobs exceed the threshold" do
      SolidQueueWeb.slow_job_threshold = 1.hour
      get "/jobs"
      expect(response.body).not_to include("Slow Jobs")
    end
  end

  describe "multi-database connects_to" do
    after { SolidQueueWeb.connects_to = nil }

    it "passes through normally when connects_to is not configured" do
      get "/jobs"
      expect(response).to have_http_status(:ok)
    end

    it "calls connected_to with the configured options when connects_to is set" do
      SolidQueueWeb.connects_to = { role: :writing }
      expect(ActiveRecord::Base).to receive(:connected_to).with(role: :writing).and_call_original
      get "/jobs"
      expect(response).to have_http_status(:ok)
    end
  end

  describe "alert webhook" do
    after do
      SolidQueueWeb.alert_webhook_url       = nil
      SolidQueueWeb.alert_failure_threshold = nil
      SolidQueueWeb::AlertWebhook.reset!
    end

    it "calls AlertWebhook with the current failed job count" do
      expect(SolidQueueWeb::AlertWebhook).to receive(:call).with(failure_count: kind_of(Integer))
      get "/jobs"
    end

    it "does not raise when webhook fires during a dashboard request" do
      SolidQueueWeb.alert_webhook_url       = "http://example.com/hook"
      SolidQueueWeb.alert_failure_threshold = 0
      allow(Thread).to receive(:new)
      get "/jobs"
      expect(response).to have_http_status(:ok)
    end
  end

  describe "authentication" do
    after { SolidQueueWeb.instance_variable_set(:@authenticate, nil) }

    it "allows access when the auth block returns truthy" do
      SolidQueueWeb.authenticate { true }
      get "/jobs"
      expect(response).to have_http_status(:ok)
    end

    it "returns 401 when the auth block returns falsy" do
      SolidQueueWeb.authenticate { false }
      get "/jobs"
      expect(response).to have_http_status(:unauthorized)
    end
  end
end
