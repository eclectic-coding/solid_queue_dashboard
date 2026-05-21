require "rails_helper"

RSpec.describe "FailedJobs::Arguments", type: :request do
  let(:job) do
    SolidQueue::Job.create!(
      queue_name: "default",
      class_name: "TestJob",
      arguments: { user_id: 42 },
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

  describe "PATCH /jobs/failed_jobs/:failed_job_id/arguments" do
    it "updates the job arguments and retries" do
      patch "/jobs/failed_jobs/#{execution.id}/arguments",
        params: { arguments: { user_id: 999 }.to_json }
      expect(response).to redirect_to("/jobs/failed_jobs")
      follow_redirect!
      expect(response.body).to include("queued for retry")
    end

    it "removes the failed execution on success" do
      expect {
        patch "/jobs/failed_jobs/#{execution.id}/arguments",
          params: { arguments: { user_id: 999 }.to_json }
      }.to change(SolidQueue::FailedExecution, :count).by(-1)
    end

    it "persists the new arguments on the job" do
      patch "/jobs/failed_jobs/#{execution.id}/arguments",
        params: { arguments: { user_id: 999 }.to_json }
      expect(job.reload.arguments).to include("user_id" => 999)
    end

    it "redirects to the job detail page on invalid JSON" do
      patch "/jobs/failed_jobs/#{execution.id}/arguments",
        params: { arguments: "not valid json{{" }
      expect(response).to redirect_to("/jobs/list/#{job.id}")
      follow_redirect!
      expect(response.body).to include("Invalid JSON")
    end

    it "leaves the failed execution in place on invalid JSON" do
      expect {
        patch "/jobs/failed_jobs/#{execution.id}/arguments",
          params: { arguments: "not valid json{{" }
      }.not_to change(SolidQueue::FailedExecution, :count)
    end

    it "handles unexpected errors gracefully" do
      allow_any_instance_of(SolidQueue::FailedExecution).to receive(:retry).and_raise(RuntimeError, "db error")
      patch "/jobs/failed_jobs/#{execution.id}/arguments",
        params: { arguments: { user_id: 1 }.to_json }
      expect(response).to redirect_to("/jobs/failed_jobs")
      follow_redirect!
      expect(response.body).to include("Could not update job")
    end
  end
end
