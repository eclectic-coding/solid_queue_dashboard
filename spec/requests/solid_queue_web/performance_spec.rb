require "rails_helper"

RSpec.describe "Performance", type: :request do
  def finished_job(class_name:, duration_seconds:, finished_ago: 1.hour)
    finished = finished_ago.ago
    job = SolidQueue::Job.new(
      queue_name: "default", class_name: class_name,
      arguments: {}.to_json, priority: 0, active_job_id: SecureRandom.uuid
    )
    job.finished_at = finished
    job.created_at  = finished - duration_seconds
    job.updated_at  = finished
    job.save!(validate: false)
    job
  end

  describe "GET /jobs/performance" do
    it "returns HTTP success" do
      get "/jobs/performance"
      expect(response).to have_http_status(:ok)
    end

    it "displays the Performance heading" do
      get "/jobs/performance"
      expect(response.body).to include("Performance")
    end

    it "shows an empty state when no finished jobs exist" do
      get "/jobs/performance"
      expect(response.body).to include("No finished jobs found")
    end

    it "renders a row for each distinct job class" do
      finished_job(class_name: "AlphaJob", duration_seconds: 10)
      finished_job(class_name: "BetaJob",  duration_seconds: 20)

      get "/jobs/performance"
      expect(response.body).to include("AlphaJob")
      expect(response.body).to include("BetaJob")
    end

    it "links each job class to the history page filtered by that class" do
      finished_job(class_name: "AlphaJob", duration_seconds: 10)

      get "/jobs/performance"
      expect(response.body).to include("/jobs/history?q=AlphaJob")
    end

    it "renders period filter pills" do
      get "/jobs/performance"
      expect(response.body).to include("1h")
      expect(response.body).to include("24h")
      expect(response.body).to include("7d")
    end

    it "filters results to the selected period" do
      finished_job(class_name: "RecentJob", duration_seconds: 5, finished_ago: 30.minutes)
      finished_job(class_name: "OldJob",    duration_seconds: 5, finished_ago: 48.hours)

      get "/jobs/performance", params: { period: "24h" }
      expect(response.body).to     include("RecentJob")
      expect(response.body).not_to include("OldJob")
    end

    it "shows empty state message with period when no jobs match the filter" do
      get "/jobs/performance", params: { period: "1h" }
      expect(response.body).to include("No finished jobs found in the last 1h")
    end

    it "renders p99 and Std Dev column headers" do
      finished_job(class_name: "WorkJob", duration_seconds: 10)

      get "/jobs/performance"
      expect(response.body).to include("p99")
      expect(response.body).to include("Std Dev")
    end

    it "renders p99 and std_dev values for a job class" do
      5.times { |i| finished_job(class_name: "WorkJob", duration_seconds: (i + 1) * 10) }

      get "/jobs/performance"
      expect(response.body).to include("WorkJob")
      expect(response.body).to include("p99")
      expect(response.body).to include("Std Dev")
    end

    it "sorts rows by p95 descending (slowest class first)" do
      finished_job(class_name: "FastJob", duration_seconds: 2)
      finished_job(class_name: "SlowJob", duration_seconds: 120)

      get "/jobs/performance"
      slow_pos = response.body.index("SlowJob")
      fast_pos = response.body.index("FastJob")
      expect(slow_pos).to be < fast_pos
    end

    describe "authentication" do
      after { SolidQueueWeb.instance_variable_set(:@authenticate, nil) }

      it "allows access when auth block returns truthy" do
        SolidQueueWeb.authenticate { true }
        get "/jobs/performance"
        expect(response).to have_http_status(:ok)
      end

      it "returns 401 when auth block returns falsy" do
        SolidQueueWeb.authenticate { false }
        get "/jobs/performance"
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end
