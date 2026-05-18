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
  end

  describe "POST /jobs/failed_jobs/:id/retry" do
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
  end

  describe "POST /jobs/failed_jobs/retry_all" do
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
  end
end
