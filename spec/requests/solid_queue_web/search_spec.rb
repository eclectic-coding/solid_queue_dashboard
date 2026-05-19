require "rails_helper"

RSpec.describe "Search", type: :request do
  let!(:ready_job) do
    SolidQueue::Job.create!(
      queue_name: "default",
      class_name: "MyWorkerJob",
      arguments: {},
      active_job_id: SecureRandom.uuid
    )
  end

  let!(:failed_job) do
    j = SolidQueue::Job.create!(
      queue_name: "mailers",
      class_name: "MyMailerJob",
      arguments: {},
      active_job_id: SecureRandom.uuid
    )
    j.ready_execution&.destroy
    SolidQueue::FailedExecution.create!(
      job: j,
      error: { exception_class: "RuntimeError", message: "boom", backtrace: [] }
    )
    j
  end

  describe "GET /jobs/search" do
    it "returns HTTP success" do
      get "/jobs/search"
      expect(response).to have_http_status(:ok)
    end

    it "renders the search form" do
      get "/jobs/search"
      expect(response.body).to include("Search by job class name")
    end

    it "renders a datalist with known job class names" do
      get "/jobs/search"
      expect(response.body).to include("job-class-list")
      expect(response.body).to include("MyWorkerJob")
      expect(response.body).to include("MyMailerJob")
    end

    it "shows no results section when query is blank" do
      get "/jobs/search"
      expect(response.body).not_to include('class="sqd-search-group"')
    end
  end

  describe "GET /jobs/search?q=" do
    it "returns matches across statuses" do
      get "/jobs/search", params: { q: "My" }
      expect(response.body).to include("MyWorkerJob")
      expect(response.body).to include("MyMailerJob")
    end

    it "groups results by status" do
      get "/jobs/search", params: { q: "My" }
      expect(response.body).to include("ready")
      expect(response.body).to include("failed")
    end

    it "is case-insensitive" do
      get "/jobs/search", params: { q: "myworker" }
      expect(response.body).to include("MyWorkerJob")
    end

    it "shows only matching jobs" do
      get "/jobs/search", params: { q: "Worker" }
      expect(response.body).to include("MyWorkerJob")
      # MyMailerJob appears in the datalist but must not appear in a result row
      expect(response.body).not_to include("MyMailerJob</a>")
    end

    it "shows empty state when nothing matches" do
      get "/jobs/search", params: { q: "NoSuchJob" }
      expect(response.body).to include("No jobs found")
    end

    it "links to the filtered jobs index for non-failed statuses" do
      get "/jobs/search", params: { q: "Worker" }
      expect(response.body).to include("status=ready")
    end

    it "links to the failed jobs page for failed results" do
      get "/jobs/search", params: { q: "Mailer" }
      expect(response.body).to include("failed_jobs")
    end

    it "links each job class name to its detail page" do
      get "/jobs/search", params: { q: "Worker" }
      expect(response.body).to include("/jobs/list/#{ready_job.id}")
    end

    it "renders a clear link when search is active" do
      get "/jobs/search", params: { q: "Worker" }
      expect(response.body).to include("Clear")
    end
  end
end
