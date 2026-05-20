require "rails_helper"

RSpec.describe "Job History", type: :request do
  def finished_job(attrs = {})
    job = SolidQueue::Job.new(
      queue_name: attrs.fetch(:queue_name, "default"),
      class_name: attrs.fetch(:class_name, "TestJob"),
      arguments:  {}.to_json,
      priority:   0,
      active_job_id: SecureRandom.uuid
    )
    job.finished_at = attrs.fetch(:finished_at, 5.minutes.ago)
    job.created_at  = job.finished_at - attrs.fetch(:duration, 30).seconds
    job.updated_at  = job.finished_at
    job.save!(validate: false)
    job
  end

  describe "GET /jobs/history" do
    it "returns HTTP success" do
      get "/jobs/history"
      expect(response).to have_http_status(:ok)
    end

    it "shows the page title" do
      get "/jobs/history"
      expect(response.body).to include("Job History")
    end

    it "displays finished jobs" do
      finished_job(class_name: "ReportGeneratorJob")
      get "/jobs/history"
      expect(response.body).to include("ReportGeneratorJob")
    end

    it "shows empty state when no finished jobs exist" do
      get "/jobs/history"
      expect(response.body).to include("No finished jobs found")
    end

    it "displays class name, queue, duration, and finished_at columns" do
      finished_job(class_name: "InvoiceJob", queue_name: "critical", duration: 45)
      get "/jobs/history"
      expect(response.body).to include("InvoiceJob")
      expect(response.body).to include("critical")
      expect(response.body).to include("45s")
    end
  end

  describe "GET /jobs/history?period=" do
    it "filters to jobs finished within the period" do
      finished_job(class_name: "RecentJob",  finished_at: 30.minutes.ago)
      finished_job(class_name: "OldJob",     finished_at: 48.hours.ago)
      get "/jobs/history", params: { period: "1h" }
      expect(response.body).to include("RecentJob")
      expect(response.body).not_to include("OldJob")
    end

    it "ignores invalid period values" do
      finished_job(class_name: "AnyJob")
      get "/jobs/history", params: { period: "bogus" }
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("AnyJob")
    end
  end

  describe "GET /jobs/history?queue=" do
    it "filters by queue name" do
      finished_job(class_name: "CriticalJob", queue_name: "critical")
      finished_job(class_name: "DefaultJob",  queue_name: "default")
      get "/jobs/history", params: { queue: "critical" }
      expect(response.body).to include("CriticalJob")
      expect(response.body).not_to include("DefaultJob")
    end

    it "shows the active queue filter with a clear link" do
      get "/jobs/history", params: { queue: "critical" }
      expect(response.body).to include("Filtering by queue")
      expect(response.body).to include("critical")
    end
  end

  describe "GET /jobs/history?q=" do
    it "filters by class name substring" do
      finished_job(class_name: "InvoiceGeneratorJob")
      finished_job(class_name: "CleanupJob")
      get "/jobs/history", params: { q: "Invoice" }
      expect(response.body).to include("InvoiceGeneratorJob")
      expect(response.body).not_to include("CleanupJob")
    end
  end

  describe "GET /jobs/history.csv (CSV export)" do
    it "returns a CSV file" do
      get "/jobs/history", params: { format: :csv }
      expect(response).to have_http_status(:ok)
      expect(response.content_type).to include("text/csv")
    end

    it "includes job class, queue, duration, and finished_at" do
      finished_job(class_name: "ExportJob", queue_name: "default")
      get "/jobs/history", params: { format: :csv }
      expect(response.body).to include("ExportJob")
      expect(response.body).to include("default")
    end

    it "includes CSV headers" do
      get "/jobs/history", params: { format: :csv }
      expect(response.body).to include("class_name")
      expect(response.body).to include("finished_at")
    end
  end
end
