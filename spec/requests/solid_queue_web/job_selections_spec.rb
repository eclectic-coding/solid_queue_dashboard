require "rails_helper"

RSpec.describe "Job Selections", type: :request do
  let!(:ready_job) do
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

  let(:ready_execution) { ready_job.ready_execution }
  let(:other_execution) { other_job.ready_execution }

  describe "DELETE /jobs/list/selection (discard selected)" do
    it "discards only the selected executions" do
      delete "/jobs/list/selection",
             params: { status: "ready", ids: [ ready_execution.id ] }
      expect(SolidQueue::ReadyExecution.where(id: ready_execution.id)).to be_empty
      expect(SolidQueue::ReadyExecution.where(id: other_execution.id)).to exist
    end

    it "redirects to the jobs list preserving status" do
      delete "/jobs/list/selection",
             params: { status: "ready", ids: [ ready_execution.id ] }
      expect(response).to redirect_to(/status=ready/)
    end

    it "preserves the period param in the redirect" do
      delete "/jobs/list/selection",
             params: { status: "ready", period: "1h", ids: [ ready_execution.id ] }
      expect(response).to redirect_to(/period=1h/)
    end

    it "discards multiple selected executions" do
      delete "/jobs/list/selection",
             params: { status: "ready", ids: [ ready_execution.id, other_execution.id ] }
      expect(SolidQueue::ReadyExecution.count).to eq(0)
    end

    it "shows a notice with the count of discarded jobs" do
      delete "/jobs/list/selection",
             params: { status: "ready", ids: [ ready_execution.id ] }
      follow_redirect!
      expect(response.body).to include("discarded")
    end

    it "rejects non-discardable statuses" do
      delete "/jobs/list/selection",
             params: { status: "claimed", ids: [ ready_execution.id ] }
      expect(response).to redirect_to(/status=claimed/)
    end
  end

  describe "GET /jobs/list with selection UI" do
    it "renders checkboxes for discardable statuses" do
      get "/jobs/list", params: { status: "ready" }
      expect(response.body).to include('type="checkbox"')
      expect(response.body).to include("selection-form")
    end

    it "does not render checkboxes for non-discardable statuses" do
      get "/jobs/list", params: { status: "claimed" }
      expect(response.body).not_to include("selection-form")
    end
  end
end
