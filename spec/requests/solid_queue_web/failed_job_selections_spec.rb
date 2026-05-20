require "rails_helper"

RSpec.describe "Failed Job Selections", type: :request do
  let!(:job) do
    SolidQueue::Job.create!(
      queue_name: "default",
      class_name: "TestJob",
      arguments: {},
      active_job_id: SecureRandom.uuid
    )
  end

  let!(:other_job) do
    SolidQueue::Job.create!(
      queue_name: "default",
      class_name: "OtherJob",
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

  let!(:other_execution) do
    other_job.ready_execution&.destroy
    SolidQueue::FailedExecution.create!(
      job: other_job,
      error: { exception_class: "RuntimeError", message: "bang", backtrace: [] }
    )
  end

  describe "POST /jobs/failed_jobs/selection (retry selected)" do
    it "retries only the selected jobs" do
      post "/jobs/failed_jobs/selection", params: { ids: [execution.id] }
      expect(SolidQueue::FailedExecution.where(id: execution.id)).to be_empty
      expect(SolidQueue::FailedExecution.where(id: other_execution.id)).to exist
    end

    it "redirects to the failed jobs list" do
      post "/jobs/failed_jobs/selection", params: { ids: [execution.id] }
      expect(response).to redirect_to("/jobs/failed_jobs")
    end

    it "shows a notice with the count of retried jobs" do
      post "/jobs/failed_jobs/selection", params: { ids: [execution.id] }
      follow_redirect!
      expect(response.body).to include("retry")
    end

    it "retries multiple selected jobs" do
      post "/jobs/failed_jobs/selection",
           params: { ids: [execution.id, other_execution.id] }
      expect(SolidQueue::FailedExecution.count).to eq(0)
    end

    it "handles unexpected errors gracefully" do
      allow(SolidQueue::FailedExecution).to receive(:retry_all).and_raise(RuntimeError, "db error")
      post "/jobs/failed_jobs/selection", params: { ids: [execution.id] }
      expect(response).to redirect_to("/jobs/failed_jobs")
      follow_redirect!
      expect(response.body).to include("Could not retry jobs")
    end
  end

  describe "DELETE /jobs/failed_jobs/selection (discard selected)" do
    it "discards only the selected jobs" do
      delete "/jobs/failed_jobs/selection", params: { ids: [execution.id] }
      expect(SolidQueue::FailedExecution.where(id: execution.id)).to be_empty
      expect(SolidQueue::FailedExecution.where(id: other_execution.id)).to exist
    end

    it "redirects to the failed jobs list" do
      delete "/jobs/failed_jobs/selection", params: { ids: [execution.id] }
      expect(response).to redirect_to("/jobs/failed_jobs")
    end

    it "shows a notice with the count of discarded jobs" do
      delete "/jobs/failed_jobs/selection", params: { ids: [execution.id] }
      follow_redirect!
      expect(response.body).to include("discarded")
    end

    it "discards multiple selected jobs" do
      delete "/jobs/failed_jobs/selection",
             params: { ids: [execution.id, other_execution.id] }
      expect(SolidQueue::FailedExecution.count).to eq(0)
    end

    it "handles unexpected errors gracefully" do
      allow(SolidQueue::FailedExecution).to receive(:discard_all_from_jobs).and_raise(RuntimeError, "db error")
      delete "/jobs/failed_jobs/selection", params: { ids: [execution.id] }
      expect(response).to redirect_to("/jobs/failed_jobs")
      follow_redirect!
      expect(response.body).to include("Could not discard jobs")
    end
  end

  describe "GET /jobs/failed_jobs with selection UI" do
    it "renders checkboxes when failed jobs exist" do
      get "/jobs/failed_jobs"
      expect(response.body).to include('type="checkbox"')
      expect(response.body).to include("retry-selection-form")
      expect(response.body).to include("discard-selection-form")
    end
  end
end
