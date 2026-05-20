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

  describe "POST /jobs/retry_all_failed" do
    let!(:failed_job) do
      j = SolidQueue::Job.create!(
        queue_name: "default", class_name: "TestJob",
        arguments: {}.to_json, active_job_id: SecureRandom.uuid
      )
      SolidQueue::FailedExecution.create!(
        job: j,
        error: { exception_class: "RuntimeError", message: "boom", backtrace: [] }
      )
      j
    end

    it "retries all failed jobs and redirects to the dashboard" do
      post "/jobs/retry_all_failed"
      expect(response).to redirect_to("/jobs/")
      follow_redirect!
      expect(response.body).to include("queued for retry")
    end

    it "removes the failed execution" do
      expect { post "/jobs/retry_all_failed" }.to change(SolidQueue::FailedExecution, :count).by(-1)
    end

    it "handles failure gracefully" do
      allow(SolidQueue::FailedExecution).to receive(:retry_all).and_raise(RuntimeError, "boom")
      post "/jobs/retry_all_failed"
      expect(response).to redirect_to("/jobs/")
      follow_redirect!
      expect(response.body).to include("Could not retry failed jobs")
    end
  end

  describe "POST /jobs/discard_all_blocked" do
    let!(:blocked_job) do
      j = SolidQueue::Job.create!(
        queue_name: "default", class_name: "TestJob",
        arguments: {}.to_json, active_job_id: SecureRandom.uuid
      )
      j.ready_execution&.destroy
      j.update!(concurrency_key: "TestJob/1")
      allow_any_instance_of(SolidQueue::BlockedExecution).to receive(:set_expires_at)
      SolidQueue::BlockedExecution.create!(
        job: j, queue_name: j.queue_name, priority: j.priority, expires_at: 1.hour.from_now
      )
      j
    end

    it "discards all blocked jobs and redirects to the dashboard" do
      post "/jobs/discard_all_blocked"
      expect(response).to redirect_to("/jobs/")
      follow_redirect!
      expect(response.body).to include("discarded")
    end

    it "removes the blocked execution" do
      expect { post "/jobs/discard_all_blocked" }.to change(SolidQueue::BlockedExecution, :count).by(-1)
    end

    it "handles failure gracefully" do
      allow(SolidQueue::BlockedExecution).to receive(:discard_all_from_jobs).and_raise(RuntimeError, "boom")
      post "/jobs/discard_all_blocked"
      expect(response).to redirect_to("/jobs/")
      follow_redirect!
      expect(response.body).to include("Could not discard blocked jobs")
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
