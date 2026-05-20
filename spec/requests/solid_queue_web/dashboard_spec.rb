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
