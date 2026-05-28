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

  describe "GET /jobs/list/:id (detail)" do
    it "returns HTTP success" do
      get "/jobs/list/#{ready_job.id}"
      expect(response).to have_http_status(:ok)
    end

    it "displays job class name and details" do
      get "/jobs/list/#{ready_job.id}"
      expect(response.body).to include("TestJob")
      expect(response.body).to include("default")
    end

    it "shows error section for failed jobs" do
      ready_job.ready_execution&.destroy
      SolidQueue::FailedExecution.create!(
        job: ready_job,
        error: { exception_class: "RuntimeError", message: "boom", backtrace: ["app/jobs/test_job.rb:1"] }
      )
      get "/jobs/list/#{ready_job.id}"
      expect(response.body).to include("RuntimeError")
      expect(response.body).to include("app/jobs/test_job.rb:1")
    end

    it "derives scheduled status when only a scheduled execution exists" do
      ready_job.ready_execution&.destroy
      ready_job.update!(scheduled_at: 1.hour.from_now)
      SolidQueue::ScheduledExecution.create!(
        job: ready_job,
        queue_name: ready_job.queue_name,
        priority: ready_job.priority
      )
      get "/jobs/list/#{ready_job.id}"
      expect(response).to have_http_status(:ok)
    end

    it "derives finished status when no execution exists" do
      ready_job.ready_execution&.destroy
      get "/jobs/list/#{ready_job.id}"
      expect(response).to have_http_status(:ok)
    end

    it "shows blocked until date for blocked jobs" do
      ready_job.ready_execution&.destroy
      ready_job.update!(concurrency_key: "TestJob/1")
      allow_any_instance_of(SolidQueue::BlockedExecution).to receive(:set_expires_at)
      SolidQueue::BlockedExecution.create!(
        job: ready_job,
        queue_name: ready_job.queue_name,
        priority: ready_job.priority,
        expires_at: 1.hour.from_now
      )
      get "/jobs/list/#{ready_job.id}"
      expect(response.body).to include("Blocked Until")
    end
  end

  describe "GET /jobs/list" do
    it "returns HTTP success" do
      get "/jobs/list"
      expect(response).to have_http_status(:ok)
    end

    it "shows ready jobs by default" do
      get "/jobs/list"
      expect(response.body).to include("TestJob")
    end
  end

  describe "GET /jobs/list?q= (class name search)" do
    let!(:other_job) do
      SolidQueue::Job.create!(
        queue_name: "default",
        class_name: "MailerJob",
        arguments: {},
        active_job_id: SecureRandom.uuid
      )
    end

    it "returns only jobs matching the search term" do
      get "/jobs/list", params: { q: "Test" }
      expect(response.body).to include("TestJob")
      expect(response.body).not_to include("MailerJob")
    end

    it "is case-insensitive" do
      get "/jobs/list", params: { q: "test" }
      expect(response.body).to include("TestJob")
    end

    it "shows empty state when search matches nothing" do
      get "/jobs/list", params: { q: "NoSuchJob" }
      expect(response.body).to include("No ready jobs")
    end

    it "renders a clear link when search is active" do
      get "/jobs/list", params: { q: "Test" }
      expect(response.body).to include("Clear")
    end

    it "persists search term across status tab links" do
      get "/jobs/list", params: { q: "Test" }
      expect(response.body).to include("q=Test")
    end
  end

  describe "GET /jobs/list?period= (time-based filter)" do
    let!(:old_job) do
      job = SolidQueue::Job.create!(
        queue_name: "default",
        class_name: "OldJob",
        arguments: {},
        active_job_id: SecureRandom.uuid
      )
      job.update_columns(created_at: 2.days.ago)
      job.ready_execution.update_columns(created_at: 2.days.ago)
      job
    end

    it "shows all jobs when no period is set" do
      get "/jobs/list"
      expect(response.body).to include("TestJob")
      expect(response.body).to include("OldJob")
    end

    it "filters to jobs enqueued within the last hour" do
      get "/jobs/list", params: { period: "1h" }
      expect(response.body).to include("TestJob")
      expect(response.body).not_to include("OldJob")
    end

    it "filters to jobs enqueued within the last 24 hours" do
      get "/jobs/list", params: { period: "24h" }
      expect(response.body).to include("TestJob")
      expect(response.body).not_to include("OldJob")
    end

    it "includes all jobs within 7 days" do
      get "/jobs/list", params: { period: "7d" }
      expect(response.body).to include("TestJob")
      expect(response.body).to include("OldJob")
    end

    it "ignores invalid period values" do
      get "/jobs/list", params: { period: "bogus" }
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("TestJob")
    end

    it "persists period across status tab links" do
      get "/jobs/list", params: { period: "1h" }
      expect(response.body).to include("period=1h")
    end
  end

  describe "DELETE /jobs/list/:id (discard single)" do
    it "discards the job and redirects (HTML)" do
      delete "/jobs/list/#{ready_execution.id}", params: { status: "ready" }
      expect(response).to redirect_to("/jobs/list?direction=desc&sort=created_at&status=ready")
      follow_redirect!
      expect(response.body).to include("discarded")
    end


    it "responds with turbo stream when last job: replaces card with empty state" do
      delete "/jobs/list/#{ready_execution.id}",
        params: { status: "ready" },
        headers: { "Accept" => "text/vnd.turbo-stream.html, text/html" }
      expect(response.content_type).to include("text/vnd.turbo-stream.html")
      expect(response.body).to include("sqd-empty")
      expect(response.body).to include("No ready jobs")
    end

    it "responds with turbo stream: removes row when more jobs remain" do
      SolidQueue::Job.create!(
        queue_name: "default", class_name: "OtherJob",
        arguments: {}, active_job_id: SecureRandom.uuid
      )
      delete "/jobs/list/#{ready_execution.id}",
        params: { status: "ready" },
        headers: { "Accept" => "text/vnd.turbo-stream.html, text/html" }
      expect(response.content_type).to include("text/vnd.turbo-stream.html")
      expect(response.body).to include("execution_#{ready_execution.id}")
      expect(response.body).to include("turbo-stream")
    end

    it "removes the execution and job" do
      expect {
        delete "/jobs/list/#{ready_execution.id}", params: { status: "ready" }
      }.to change(SolidQueue::ReadyExecution, :count).by(-1)
        .and change(SolidQueue::Job, :count).by(-1)
    end

    it "rejects discard for claimed status" do
      delete "/jobs/list/#{ready_execution.id}", params: { status: "claimed" }
      expect(response).to redirect_to("/jobs/list?direction=desc&sort=created_at&status=claimed")
      follow_redirect!
      expect(response.body).to include("Cannot discard")
    end

    it "handles unexpected errors gracefully" do
      allow_any_instance_of(SolidQueue::ReadyExecution).to receive(:discard).and_raise(RuntimeError, "disk full")
      delete "/jobs/list/#{ready_execution.id}", params: { status: "ready" }
      expect(response).to redirect_to("/jobs/list?direction=desc&sort=created_at&status=ready")
      follow_redirect!
      expect(response.body).to include("Could not discard job")
    end
  end

  describe "GET /jobs/list.csv (CSV export)" do
    it "returns a CSV file" do
      get "/jobs/list", params: { status: "ready" }, headers: { "Accept" => "text/csv" }
      expect(response).to have_http_status(:ok)
      expect(response.content_type).to include("text/csv")
    end

    it "includes the job class name and queue" do
      get "/jobs/list", params: { status: "ready", format: :csv }
      expect(response.body).to include("TestJob")
      expect(response.body).to include("default")
    end

    it "includes CSV headers" do
      get "/jobs/list", params: { status: "ready", format: :csv }
      expect(response.body).to include("class_name")
      expect(response.body).to include("queue_name")
    end
  end

  describe "POST /jobs/list/discard_all" do
    it "discards all ready jobs and redirects" do
      post "/jobs/list/discard_all", params: { status: "ready" }
      expect(response).to redirect_to("/jobs/list?direction=desc&sort=created_at&status=ready")
      follow_redirect!
      expect(response.body).to include("discarded")
    end

    it "clears all ready executions" do
      expect {
        post "/jobs/list/discard_all", params: { status: "ready" }
      }.to change(SolidQueue::ReadyExecution, :count).to(0)
    end

    it "rejects discard_all for claimed status" do
      post "/jobs/list/discard_all", params: { status: "claimed" }
      expect(response).to redirect_to("/jobs/list?direction=desc&sort=created_at&status=claimed")
      follow_redirect!
      expect(response.body).to include("Cannot discard")
    end

    it "handles unexpected errors gracefully" do
      allow(SolidQueue::ReadyExecution).to receive(:discard_all_from_jobs).and_raise(RuntimeError, "disk full")
      post "/jobs/list/discard_all", params: { status: "ready" }
      expect(response).to redirect_to("/jobs/list?direction=desc&sort=created_at&status=ready")
      follow_redirect!
      expect(response.body).to include("Could not discard jobs")
    end
  end

  describe "GET /jobs/list?sort=" do
    it "accepts sort by class_name" do
      get "/jobs/list", params: { sort: "class_name", direction: "asc" }
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("TestJob")
    end

    it "accepts sort by queue_name" do
      get "/jobs/list", params: { sort: "queue_name", direction: "desc" }
      expect(response).to have_http_status(:ok)
    end

    it "accepts sort by priority" do
      get "/jobs/list", params: { sort: "priority", direction: "asc" }
      expect(response).to have_http_status(:ok)
    end

    it "defaults to created_at desc for invalid sort column" do
      get "/jobs/list", params: { sort: "DROP TABLE", direction: "evil" }
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("TestJob")
    end

    it "preserves sort across status tab links" do
      get "/jobs/list", params: { sort: "class_name", direction: "asc" }
      expect(response.body).to include("sort=class_name")
      expect(response.body).to include("direction=asc")
    end
  end

  describe "slow job detection (claimed tab)" do
    let!(:worker_process) do
      SolidQueue::Process.create!(
        kind: "Worker", pid: 99_999, hostname: "test-host",
        name: "worker-test", last_heartbeat_at: Time.current
      )
    end

    let!(:claimed_job) do
      SolidQueue::Job.create!(
        queue_name: "default", class_name: "SlowJob",
        arguments: {}, active_job_id: SecureRandom.uuid
      )
    end

    let!(:claimed_execution) do
      SolidQueue::ClaimedExecution.create!(job: claimed_job, process: worker_process)
    end

    after { SolidQueueWeb.slow_job_threshold = nil }

    it "shows the Running For column on the claimed tab" do
      get "/jobs/list", params: { status: "claimed" }
      expect(response.body).to include("Running For")
    end

    it "does not show the Running For column on other tabs" do
      get "/jobs/list", params: { status: "ready" }
      expect(response.body).not_to include("Running For")
    end

    it "highlights slow jobs when threshold is configured and exceeded" do
      SolidQueueWeb.slow_job_threshold = 1.second
      claimed_execution.update_columns(created_at: 10.minutes.ago)

      get "/jobs/list", params: { status: "claimed" }
      expect(response.body).to include('class="sqd-row--slow"')
      expect(response.body).to include("sqd-badge--slow")
    end

    it "does not highlight jobs within the threshold" do
      SolidQueueWeb.slow_job_threshold = 1.hour
      get "/jobs/list", params: { status: "claimed" }
      expect(response.body).not_to include('class="sqd-row--slow"')
    end

    it "does not highlight any row when threshold is not configured" do
      claimed_execution.update_columns(created_at: 10.hours.ago)
      get "/jobs/list", params: { status: "claimed" }
      expect(response.body).not_to include('class="sqd-row--slow"')
    end
  end

  describe "job wait time column (claimed tab)" do
    let!(:worker_process) do
      SolidQueue::Process.create!(
        kind: "Worker", pid: 88_888, hostname: "test-host",
        name: "worker-wait-test", last_heartbeat_at: Time.current
      )
    end

    let!(:claimed_job) do
      SolidQueue::Job.create!(
        queue_name: "default", class_name: "WaitTestJob",
        arguments: {}, active_job_id: SecureRandom.uuid
      )
    end

    let!(:claimed_execution) do
      execution = SolidQueue::ClaimedExecution.create!(job: claimed_job, process: worker_process)
      claimed_job.update_columns(created_at: 5.minutes.ago)
      execution.update_columns(created_at: 2.minutes.ago)
      execution
    end

    it "shows the Wait Time column header on the claimed tab" do
      get "/jobs/list", params: { status: "claimed" }
      expect(response.body).to include("Wait Time")
    end

    it "does not show the Wait Time column on other tabs" do
      get "/jobs/list", params: { status: "ready" }
      expect(response.body).not_to include("Wait Time")
    end

    it "renders a formatted wait time for each claimed job" do
      get "/jobs/list", params: { status: "claimed" }
      expect(response.body).to include("3m")
    end

    it "includes wait_time_seconds in the claimed CSV export" do
      get "/jobs/list.csv", params: { status: "claimed" }
      expect(response.body).to include("wait_time_seconds")
      row = response.body.lines.last
      expect(row.split(",").last.strip.to_i).to be_within(5).of(180)
    end

    it "does not include wait_time_seconds in CSV for other statuses" do
      get "/jobs/list.csv", params: { status: "ready" }
      expect(response.body).not_to include("wait_time_seconds")
    end
  end

  describe "GET /jobs/list?priority= (priority filter)" do
    let!(:high_priority_job) do
      SolidQueue::Job.create!(
        queue_name: "default", class_name: "HighPriorityJob",
        arguments: {}, active_job_id: SecureRandom.uuid, priority: 0
      )
    end

    let!(:low_priority_job) do
      SolidQueue::Job.create!(
        queue_name: "default", class_name: "LowPriorityJob",
        arguments: {}, active_job_id: SecureRandom.uuid, priority: 10
      )
    end

    it "shows all jobs when no priority filter is set" do
      get "/jobs/list", params: { status: "ready" }
      expect(response.body).to include("HighPriorityJob")
      expect(response.body).to include("LowPriorityJob")
    end

    it "filters to only jobs with the specified priority" do
      get "/jobs/list", params: { status: "ready", priority: "10" }
      expect(response.body).to     include("LowPriorityJob")
      expect(response.body).not_to include("HighPriorityJob")
    end

    it "renders the priority select dropdown when multiple priorities exist" do
      get "/jobs/list", params: { status: "ready" }
      expect(response.body).to include("sqd-select")
      expect(response.body).to include("All priorities")
    end

    it "preserves priority across status tab links" do
      get "/jobs/list", params: { status: "ready", priority: "0" }
      expect(response.body).to include("priority=0")
    end

    it "discard all respects the priority filter" do
      post "/jobs/list/discard_all", params: { status: "ready", priority: "10" }
      expect(SolidQueue::ReadyExecution.exists?(job: high_priority_job)).to be true
      expect(SolidQueue::ReadyExecution.exists?(job: low_priority_job)).to  be false
    end
  end
end
