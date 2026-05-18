require "rails_helper"

RSpec.describe "Processes", type: :request do
  let!(:process) do
    SolidQueue::Process.create!(
      kind: "Worker",
      name: "worker-0-web-1",
      pid: 12_345,
      hostname: "web-1.local",
      last_heartbeat_at: 5.seconds.ago,
      metadata: { queues: %w[default], thread_count: 2 }
    )
  end

  describe "GET /jobs/processes" do
    it "returns HTTP success" do
      get "/jobs/processes"
      expect(response).to have_http_status(:ok)
    end

    it "displays process kind and name" do
      get "/jobs/processes"
      expect(response.body).to include("Worker")
      expect(response.body).to include("worker-0-web-1")
    end

    it "shows Healthy badge for a recent heartbeat" do
      get "/jobs/processes"
      expect(response.body).to include("Healthy")
    end

    it "shows Stale badge for an old heartbeat" do
      process.update!(last_heartbeat_at: 10.minutes.ago)
      get "/jobs/processes"
      expect(response.body).to include("Stale")
    end
  end
end
