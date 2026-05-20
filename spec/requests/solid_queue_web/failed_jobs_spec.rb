require "rails_helper"

RSpec.describe "FailedJobs", type: :request do
  let(:job) do
    SolidQueue::Job.create!(
      queue_name: "default",
      class_name: "TestJob",
      arguments: {},
      active_job_id: SecureRandom.uuid
    )
  end

  let!(:execution) do
    job.ready_execution&.destroy
    SolidQueue::FailedExecution.create!(
      job: job,
      error: { exception_class: "RuntimeError", message: "boom", backtrace: [] }
    )
  end

  describe "GET /jobs/failed_jobs" do
    it "returns HTTP success" do
      get "/jobs/failed_jobs"
      expect(response).to have_http_status(:ok)
    end

    it "displays failed job class name" do
      get "/jobs/failed_jobs"
      expect(response.body).to include("TestJob")
    end

    it "renders a search form" do
      get "/jobs/failed_jobs"
      expect(response.body).to include("Filter by job class")
    end
  end

  describe "GET /jobs/failed_jobs?q= (class name search)" do
    let!(:other_job) do
      j = SolidQueue::Job.create!(
        queue_name: "default",
        class_name: "MailerJob",
        arguments: {},
        active_job_id: SecureRandom.uuid
      )
      j.ready_execution&.destroy
      SolidQueue::FailedExecution.create!(
        job: j,
        error: { exception_class: "RuntimeError", message: "oops", backtrace: [] }
      )
      j
    end

    it "returns only matching jobs" do
      get "/jobs/failed_jobs", params: { q: "Test" }
      expect(response.body).to include("TestJob")
      expect(response.body).not_to include("MailerJob")
    end

    it "renders a clear link when search is active" do
      get "/jobs/failed_jobs", params: { q: "Test" }
      expect(response.body).to include("Clear")
    end
  end

  describe "GET /jobs/failed_jobs?queue= (queue filter)" do
    let!(:other_job) do
      j = SolidQueue::Job.create!(
        queue_name: "mailers",
        class_name: "MailerJob",
        arguments: {},
        active_job_id: SecureRandom.uuid
      )
      j.ready_execution&.destroy
      SolidQueue::FailedExecution.create!(
        job: j,
        error: { exception_class: "RuntimeError", message: "oops", backtrace: [] }
      )
      j
    end

    it "returns only jobs in the specified queue" do
      get "/jobs/failed_jobs", params: { queue: "default" }
      expect(response.body).to include("TestJob")
      expect(response.body).not_to include("MailerJob")
    end

    it "shows queue filter indicator" do
      get "/jobs/failed_jobs", params: { queue: "default" }
      expect(response.body).to include("Filtering by queue")
    end

    it "queue names in the table link to the queue filter" do
      get "/jobs/failed_jobs"
      expect(response.body).to include("queue=default")
    end
  end

  describe "GET /jobs/failed_jobs?period= (time-based filter)" do
    let!(:old_execution) do
      j = SolidQueue::Job.create!(
        queue_name: "default",
        class_name: "OldFailedJob",
        arguments: {},
        active_job_id: SecureRandom.uuid
      )
      j.ready_execution&.destroy
      exec = SolidQueue::FailedExecution.create!(
        job: j,
        error: { exception_class: "RuntimeError", message: "old", backtrace: [] }
      )
      j.update_columns(created_at: 2.days.ago)
      exec
    end

    it "shows all failed jobs when no period is set" do
      get "/jobs/failed_jobs"
      expect(response.body).to include("TestJob")
      expect(response.body).to include("OldFailedJob")
    end

    it "filters to jobs failed within the last hour" do
      get "/jobs/failed_jobs", params: { period: "1h" }
      expect(response.body).to include("TestJob")
      expect(response.body).not_to include("OldFailedJob")
    end

    it "ignores invalid period values" do
      get "/jobs/failed_jobs", params: { period: "bogus" }
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("TestJob")
    end

    it "persists period across bulk action params" do
      get "/jobs/failed_jobs", params: { period: "1h" }
      expect(response.body).to include("period=1h")
    end
  end

  describe "POST /jobs/failed_jobs/:id/retry (RetryFailedJobsController#create)" do
    it "retries the job and redirects" do
      post "/jobs/failed_jobs/#{execution.id}/retry"
      expect(response).to redirect_to("/jobs/failed_jobs")
      follow_redirect!
      expect(response.body).to include("queued for retry")
    end

    it "removes the failed execution" do
      expect {
        post "/jobs/failed_jobs/#{execution.id}/retry"
      }.to change(SolidQueue::FailedExecution, :count).by(-1)
    end

    it "handles retry failure gracefully" do
      allow(SolidQueue::FailedExecution).to receive(:retry_all).and_raise(RuntimeError, "boom")
      post "/jobs/failed_jobs/#{execution.id}/retry"
      expect(response).to redirect_to("/jobs/failed_jobs")
      follow_redirect!
      expect(response.body).to include("Could not retry job")
    end
  end

  describe "DELETE /jobs/failed_jobs/:id" do
    it "discards the job and redirects" do
      delete "/jobs/failed_jobs/#{execution.id}"
      expect(response).to redirect_to("/jobs/failed_jobs")
      follow_redirect!
      expect(response.body).to include("discarded")
    end

    it "removes the failed execution and job" do
      expect {
        delete "/jobs/failed_jobs/#{execution.id}"
      }.to change(SolidQueue::FailedExecution, :count).by(-1)
        .and change(SolidQueue::Job, :count).by(-1)
    end

    it "handles discard failure gracefully" do
      allow(SolidQueue::FailedExecution).to receive(:discard_all_from_jobs).and_raise(RuntimeError, "boom")
      delete "/jobs/failed_jobs/#{execution.id}"
      expect(response).to redirect_to("/jobs/failed_jobs")
      follow_redirect!
      expect(response.body).to include("Could not discard job")
    end
  end

  describe "POST /jobs/failed_jobs/retry_all (RetryFailedJobsController#create)" do
    it "retries all failed jobs and redirects" do
      post "/jobs/failed_jobs/retry_all"
      expect(response).to redirect_to("/jobs/failed_jobs")
      follow_redirect!
      expect(response.body).to include("queued for retry")
    end

    it "clears all failed executions" do
      expect {
        post "/jobs/failed_jobs/retry_all"
      }.to change(SolidQueue::FailedExecution, :count).to(0)
    end

    it "scopes retry to the specified queue" do
      other_job = SolidQueue::Job.create!(
        queue_name: "mailers",
        class_name: "MailerJob",
        arguments: {},
        active_job_id: SecureRandom.uuid
      )
      other_job.ready_execution&.destroy
      SolidQueue::FailedExecution.create!(
        job: other_job,
        error: { exception_class: "RuntimeError", message: "oops", backtrace: [] }
      )

      post "/jobs/failed_jobs/retry_all", params: { queue: "default" }
      expect(SolidQueue::FailedExecution.joins(:job).where(solid_queue_jobs: { queue_name: "mailers" }).count).to eq(1)
    end

    it "preserves queue param in redirect" do
      post "/jobs/failed_jobs/retry_all", params: { queue: "default" }
      expect(response).to redirect_to("/jobs/failed_jobs?queue=default")
    end
  end

  describe "GET /jobs/failed_jobs.csv (CSV export)" do
    it "returns a CSV file" do
      get "/jobs/failed_jobs", params: { format: :csv }
      expect(response).to have_http_status(:ok)
      expect(response.content_type).to include("text/csv")
    end

    it "includes the job class name, queue, and error details" do
      get "/jobs/failed_jobs", params: { format: :csv }
      expect(response.body).to include("TestJob")
      expect(response.body).to include("default")
      expect(response.body).to include("RuntimeError")
    end

    it "includes CSV headers" do
      get "/jobs/failed_jobs", params: { format: :csv }
      expect(response.body).to include("class_name")
      expect(response.body).to include("error_class")
    end
  end

  describe "POST /jobs/failed_jobs/discard_all" do
    it "discards all failed jobs and redirects" do
      post "/jobs/failed_jobs/discard_all"
      expect(response).to redirect_to("/jobs/failed_jobs")
      follow_redirect!
      expect(response.body).to include("discarded")
    end

    it "clears all failed executions and jobs" do
      expect {
        post "/jobs/failed_jobs/discard_all"
      }.to change(SolidQueue::FailedExecution, :count).to(0)
    end

    it "scopes discard to the specified queue" do
      other_job = SolidQueue::Job.create!(
        queue_name: "mailers",
        class_name: "MailerJob",
        arguments: {},
        active_job_id: SecureRandom.uuid
      )
      other_job.ready_execution&.destroy
      SolidQueue::FailedExecution.create!(
        job: other_job,
        error: { exception_class: "RuntimeError", message: "oops", backtrace: [] }
      )

      post "/jobs/failed_jobs/discard_all", params: { queue: "default" }
      expect(SolidQueue::FailedExecution.joins(:job).where(solid_queue_jobs: { queue_name: "mailers" }).count).to eq(1)
    end

    it "preserves queue param in redirect" do
      post "/jobs/failed_jobs/discard_all", params: { queue: "default" }
      expect(response).to redirect_to("/jobs/failed_jobs?queue=default")
    end
  end
end
