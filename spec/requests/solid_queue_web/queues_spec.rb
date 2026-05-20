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

    it "shows Done (24h) and Failed (24h) columns" do
      get "/jobs/queues"
      expect(response.body).to include("Done (24h)")
      expect(response.body).to include("Failed (24h)")
    end

    it "shows formatted latency for a queue with ready jobs" do
      get "/jobs/queues"
      expect(response.body).to include("Latency")
      expect(response.body).to match(/\d+s|\d+m \d+s|\d+h \d+m/)
    end

    it "shows a dash for queues with no ready jobs" do
      SolidQueue::ReadyExecution.delete_all
      get "/jobs/queues"
      expect(response.body).to include("—")
    end

    it "shows completed count for a queue" do
      job = SolidQueue::Job.new(
        queue_name: "default", class_name: "TestJob",
        arguments: {}.to_json, priority: 0, active_job_id: SecureRandom.uuid
      )
      job.finished_at = 1.hour.ago
      job.created_at  = 2.hours.ago
      job.updated_at  = 1.hour.ago
      job.save!(validate: false)

      get "/jobs/queues"
      expect(response.body).to include("Done (24h)")
    end

    it "shows failed count for a queue" do
      failed_job = SolidQueue::Job.create!(
        queue_name: "default", class_name: "TestJob",
        arguments: {}.to_json, active_job_id: SecureRandom.uuid
      )
      SolidQueue::FailedExecution.create!(
        job: failed_job,
        error: { exception_class: "RuntimeError", message: "boom", backtrace: [] }
      )

      get "/jobs/queues"
      expect(response.body).to include("Failed (24h)")
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

  describe "DELETE /jobs/queues/:name/pause" do
    before { SolidQueue::Pause.create!(queue_name: "default") }

    it "resumes the queue and redirects" do
      delete "/jobs/queues/default/pause"
      expect(response).to redirect_to("/jobs/queues")
      follow_redirect!
      expect(response.body).to include("resumed")
    end

    it "removes the Pause record" do
      expect {
        delete "/jobs/queues/default/pause"
      }.to change(SolidQueue::Pause, :count).by(-1)
    end

    it "handles resume failure gracefully" do
      allow_any_instance_of(SolidQueue::Queue).to receive(:resume).and_raise(RuntimeError, "boom")
      delete "/jobs/queues/default/pause"
      expect(response).to redirect_to("/jobs/queues")
      follow_redirect!
      expect(response.body).to include("Could not resume queue")
    end
  end
end
