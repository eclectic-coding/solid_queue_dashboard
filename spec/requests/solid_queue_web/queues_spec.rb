require "rails_helper"

RSpec.describe "Queues", type: :request do
  before do
    SolidQueue::Job.create!(
      queue_name: "default",
      class_name: "TestJob",
      arguments: {},
      active_job_id: SecureRandom.uuid
    )
  end

  describe "GET /jobs/queues" do
    it "returns HTTP success" do
      get "/jobs/queues"
      expect(response).to have_http_status(:ok)
    end

    it "displays queue names" do
      get "/jobs/queues"
      expect(response.body).to include("default")
    end
  end

  describe "POST /jobs/queues/:name/pause" do
    it "pauses the queue and redirects" do
      post "/jobs/queues/default/pause"
      expect(response).to redirect_to("/jobs/queues")
      follow_redirect!
      expect(response.body).to include("paused")
    end

    it "creates a Pause record" do
      expect {
        post "/jobs/queues/default/pause"
      }.to change(SolidQueue::Pause, :count).by(1)
    end

    it "handles pause failure gracefully" do
      allow_any_instance_of(SolidQueue::Queue).to receive(:pause).and_raise(RuntimeError, "boom")
      post "/jobs/queues/default/pause"
      expect(response).to redirect_to("/jobs/queues")
      follow_redirect!
      expect(response.body).to include("Could not pause queue")
    end
  end

  describe "POST /jobs/queues/:name/resume" do
    before { SolidQueue::Pause.create!(queue_name: "default") }

    it "resumes the queue and redirects" do
      post "/jobs/queues/default/resume"
      expect(response).to redirect_to("/jobs/queues")
      follow_redirect!
      expect(response.body).to include("resumed")
    end

    it "removes the Pause record" do
      expect {
        post "/jobs/queues/default/resume"
      }.to change(SolidQueue::Pause, :count).by(-1)
    end

    it "handles resume failure gracefully" do
      allow_any_instance_of(SolidQueue::Queue).to receive(:resume).and_raise(RuntimeError, "boom")
      post "/jobs/queues/default/resume"
      expect(response).to redirect_to("/jobs/queues")
      follow_redirect!
      expect(response.body).to include("Could not resume queue")
    end
  end
end
