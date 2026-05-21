require "rails_helper"

RSpec.describe "Metrics", type: :request do
  describe "GET /jobs/metrics.json" do
    it "returns HTTP success" do
      get "/jobs/metrics.json"
      expect(response).to have_http_status(:ok)
    end

    it "responds with JSON content type" do
      get "/jobs/metrics.json"
      expect(response.content_type).to match(%r{application/json})
    end

    it "includes a generated_at timestamp" do
      get "/jobs/metrics.json"
      data = JSON.parse(response.body)
      expect(data["generated_at"]).to match(/\A\d{4}-\d{2}-\d{2}T/)
    end

    it "includes job counts for all statuses" do
      get "/jobs/metrics.json"
      data = JSON.parse(response.body)
      expect(data["jobs"].keys).to match_array(%w[ready scheduled claimed blocked failed])
    end

    it "reflects actual job counts" do
      SolidQueue::Job.create!(
        queue_name: "default", class_name: "TestJob",
        arguments: {}.to_json, priority: 0, active_job_id: SecureRandom.uuid
      )
      get "/jobs/metrics.json"
      data = JSON.parse(response.body)
      expect(data["jobs"]["ready"]).to be >= 1
    end

    it "includes throughput with completed_1h and completed_24h" do
      get "/jobs/metrics.json"
      data = JSON.parse(response.body)
      expect(data["throughput"].keys).to match_array(%w[completed_1h completed_24h])
      expect(data["throughput"]["completed_1h"]).to be_a(Integer)
      expect(data["throughput"]["completed_24h"]).to be_a(Integer)
    end

    it "includes queues array with name, depth, and paused" do
      SolidQueue::Job.create!(
        queue_name: "metrics-test", class_name: "TestJob",
        arguments: {}.to_json, priority: 0, active_job_id: SecureRandom.uuid
      )
      get "/jobs/metrics.json"
      data = JSON.parse(response.body)
      expect(data["queues"]).to be_an(Array)
      queue = data["queues"].find { |q| q["name"] == "metrics-test" }
      expect(queue).to include("name" => "metrics-test", "depth" => 1, "paused" => false)
    end

    it "includes process summary" do
      SolidQueue::Process.create!(
        kind: "Worker", pid: 77_777, hostname: "test-host",
        name: "worker-metrics-test", last_heartbeat_at: Time.current
      )
      get "/jobs/metrics.json"
      data = JSON.parse(response.body)
      expect(data["processes"].keys).to match_array(%w[total healthy stale by_kind])
      expect(data["processes"]["total"]).to be >= 1
    end

    it "counts healthy vs stale processes correctly" do
      SolidQueue::Process.create!(
        kind: "Worker", pid: 77_778, hostname: "test-host",
        name: "worker-healthy", last_heartbeat_at: Time.current
      )
      stale = SolidQueue::Process.create!(
        kind: "Worker", pid: 77_779, hostname: "test-host",
        name: "worker-stale", last_heartbeat_at: Time.current
      )
      stale.update_columns(last_heartbeat_at: 2.hours.ago)

      get "/jobs/metrics.json"
      data = JSON.parse(response.body)
      expect(data["processes"]["healthy"]).to be >= 1
      expect(data["processes"]["stale"]).to be >= 1
    end

    it "does not include slow_jobs key when threshold is not configured" do
      get "/jobs/metrics.json"
      data = JSON.parse(response.body)
      expect(data).not_to have_key("slow_jobs")
    end

    it "includes slow_jobs count when threshold is configured" do
      SolidQueueWeb.slow_job_threshold = 1.second
      process = SolidQueue::Process.create!(
        kind: "Worker", pid: 77_780, hostname: "test-host",
        name: "worker-slow-m", last_heartbeat_at: Time.current
      )
      job = SolidQueue::Job.create!(
        queue_name: "default", class_name: "SlowJob",
        arguments: {}.to_json, priority: 0, active_job_id: SecureRandom.uuid
      )
      SolidQueue::ClaimedExecution.create!(job: job, process: process)
        .tap { |e| e.update_columns(created_at: 10.minutes.ago) }

      get "/jobs/metrics.json"
      data = JSON.parse(response.body)
      expect(data["slow_jobs"]).to be >= 1
    ensure
      SolidQueueWeb.slow_job_threshold = nil
    end

    describe "authentication" do
      after { SolidQueueWeb.instance_variable_set(:@authenticate, nil) }

      it "allows access when auth block returns truthy" do
        SolidQueueWeb.authenticate { true }
        get "/jobs/metrics.json"
        expect(response).to have_http_status(:ok)
      end

      it "returns 401 when auth block returns falsy" do
        SolidQueueWeb.authenticate { false }
        get "/jobs/metrics.json"
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end
