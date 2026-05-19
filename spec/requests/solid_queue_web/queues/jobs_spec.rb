require "rails_helper"

RSpec.describe "Queues::Jobs", type: :request do
  let!(:job) do
    SolidQueue::Job.create!(
      queue_name: "default",
      class_name: "TestJob",
      arguments: {},
      active_job_id: SecureRandom.uuid
    )
  end

  let(:execution) { job.ready_execution }

  describe "GET /jobs/queues/:queue_name/list" do
    it "returns HTTP success" do
      get "/jobs/queues/default/list"
      expect(response).to have_http_status(:ok)
    end

    it "shows jobs in the specified queue" do
      get "/jobs/queues/default/list"
      expect(response.body).to include("TestJob")
    end

    it "excludes jobs from other queues" do
      SolidQueue::Job.create!(
        queue_name: "mailers",
        class_name: "MailerJob",
        arguments: {},
        active_job_id: SecureRandom.uuid
      )
      get "/jobs/queues/default/list"
      expect(response.body).not_to include("MailerJob")
    end

    it "shows empty state for an empty queue" do
      get "/jobs/queues/other/list"
      expect(response.body).to include("No ready jobs in other")
    end

    it "displays a breadcrumb linking back to queues" do
      get "/jobs/queues/default/list"
      expect(response.body).to include("Queues")
    end

    it "filters by status" do
      job.ready_execution&.destroy
      job.update!(scheduled_at: 1.hour.from_now)
      SolidQueue::ScheduledExecution.create!(
        job: job, queue_name: job.queue_name, priority: job.priority
      )
      get "/jobs/queues/default/list", params: { status: "scheduled" }
      expect(response.body).to include("TestJob")
    end

    it "filters by class name search" do
      SolidQueue::Job.create!(
        queue_name: "default",
        class_name: "MailerJob",
        arguments: {},
        active_job_id: SecureRandom.uuid
      )
      get "/jobs/queues/default/list", params: { q: "Test" }
      expect(response.body).to include("TestJob")
      expect(response.body).not_to include("MailerJob")
    end

    it "renders a clear link when search is active" do
      get "/jobs/queues/default/list", params: { q: "Test" }
      expect(response.body).to include("Clear")
    end
  end

  describe "DELETE /jobs/queues/:queue_name/list/:id" do
    it "discards the job and redirects" do
      delete "/jobs/queues/default/list/#{execution.id}", params: { status: "ready" }
      expect(response).to redirect_to("/jobs/queues/default/list?status=ready")
      follow_redirect!
      expect(response.body).to include("discarded")
    end

    it "removes the execution and job" do
      expect {
        delete "/jobs/queues/default/list/#{execution.id}", params: { status: "ready" }
      }.to change(SolidQueue::ReadyExecution, :count).by(-1)
        .and change(SolidQueue::Job, :count).by(-1)
    end

    it "responds with turbo stream: removes row when more jobs remain" do
      SolidQueue::Job.create!(
        queue_name: "default", class_name: "OtherJob",
        arguments: {}, active_job_id: SecureRandom.uuid
      )
      delete "/jobs/queues/default/list/#{execution.id}",
        params: { status: "ready" },
        headers: { "Accept" => "text/vnd.turbo-stream.html, text/html" }
      expect(response.content_type).to include("text/vnd.turbo-stream.html")
      expect(response.body).to include("execution_#{execution.id}")
    end

    it "responds with turbo stream: replaces card with empty state when last job" do
      delete "/jobs/queues/default/list/#{execution.id}",
        params: { status: "ready" },
        headers: { "Accept" => "text/vnd.turbo-stream.html, text/html" }
      expect(response.content_type).to include("text/vnd.turbo-stream.html")
      expect(response.body).to include("sqd-empty")
      expect(response.body).to include("No ready jobs in default")
    end

    it "rejects discard of claimed jobs" do
      delete "/jobs/queues/default/list/#{execution.id}", params: { status: "claimed" }
      expect(response).to redirect_to("/jobs/queues/default/list?status=claimed")
      follow_redirect!
      expect(response.body).to include("Cannot discard")
    end

    it "handles unexpected errors gracefully" do
      allow_any_instance_of(SolidQueue::ReadyExecution).to receive(:discard).and_raise(RuntimeError, "disk full")
      delete "/jobs/queues/default/list/#{execution.id}", params: { status: "ready" }
      expect(response).to redirect_to("/jobs/queues/default/list?status=ready")
      follow_redirect!
      expect(response.body).to include("Could not discard job")
    end
  end

  describe "POST /jobs/queues/:queue_name/list/discard_all" do
    it "discards all ready jobs in the queue and redirects" do
      post "/jobs/queues/default/list/discard_all", params: { status: "ready" }
      expect(response).to redirect_to("/jobs/queues/default/list?status=ready")
      follow_redirect!
      expect(response.body).to include("discarded")
    end

    it "clears executions only in the specified queue" do
      SolidQueue::Job.create!(
        queue_name: "mailers", class_name: "MailerJob",
        arguments: {}, active_job_id: SecureRandom.uuid
      )
      expect {
        post "/jobs/queues/default/list/discard_all", params: { status: "ready" }
      }.to change(SolidQueue::ReadyExecution, :count).by(-1)
      expect(SolidQueue::ReadyExecution.joins(:job).where(solid_queue_jobs: { queue_name: "mailers" }).count).to eq(1)
    end

    it "rejects discard_all for claimed status" do
      post "/jobs/queues/default/list/discard_all", params: { status: "claimed" }
      expect(response).to redirect_to("/jobs/queues/default/list?status=claimed")
      follow_redirect!
      expect(response.body).to include("Cannot discard")
    end

    it "handles unexpected errors gracefully" do
      allow(SolidQueue::ReadyExecution).to receive(:discard_all_from_jobs).and_raise(RuntimeError, "disk full")
      post "/jobs/queues/default/list/discard_all", params: { status: "ready" }
      expect(response).to redirect_to("/jobs/queues/default/list?status=ready")
      follow_redirect!
      expect(response.body).to include("Could not discard jobs")
    end
  end
end
