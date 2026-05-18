require "rails_helper"

RSpec.describe "Jobs", type: :request do
  let!(:ready_job) do
    SolidQueue::Job.create!(
      queue_name: "default",
      class_name: "TestJob",
      arguments: {},
      active_job_id: SecureRandom.uuid
    )
  end

  let(:ready_execution) { ready_job.ready_execution }

  describe "GET /jobs/jobs" do
    it "returns HTTP success" do
      get "/jobs/jobs"
      expect(response).to have_http_status(:ok)
    end

    it "shows ready jobs by default" do
      get "/jobs/jobs"
      expect(response.body).to include("TestJob")
    end
  end

  describe "DELETE /jobs/jobs/:id (discard single)" do
    it "discards the job and redirects" do
      delete "/jobs/jobs/#{ready_execution.id}", params: { status: "ready" }
      expect(response).to redirect_to("/jobs/jobs?status=ready")
      follow_redirect!
      expect(response.body).to include("discarded")
    end

    it "removes the execution and job" do
      expect {
        delete "/jobs/jobs/#{ready_execution.id}", params: { status: "ready" }
      }.to change(SolidQueue::ReadyExecution, :count).by(-1)
        .and change(SolidQueue::Job, :count).by(-1)
    end

    it "rejects discard for claimed status" do
      delete "/jobs/jobs/#{ready_execution.id}", params: { status: "claimed" }
      expect(response).to redirect_to("/jobs/jobs?status=claimed")
      follow_redirect!
      expect(response.body).to include("Cannot discard")
    end
  end

  describe "POST /jobs/jobs/discard_all" do
    it "discards all ready jobs and redirects" do
      post "/jobs/jobs/discard_all", params: { status: "ready" }
      expect(response).to redirect_to("/jobs/jobs?status=ready")
      follow_redirect!
      expect(response.body).to include("discarded")
    end

    it "clears all ready executions" do
      expect {
        post "/jobs/jobs/discard_all", params: { status: "ready" }
      }.to change(SolidQueue::ReadyExecution, :count).to(0)
    end

    it "rejects discard_all for claimed status" do
      post "/jobs/jobs/discard_all", params: { status: "claimed" }
      expect(response).to redirect_to("/jobs/jobs?status=claimed")
      follow_redirect!
      expect(response.body).to include("Cannot discard")
    end
  end
end
