require "rails_helper"

RSpec.describe "FailedJobErrors", type: :request do
  def failed_execution(class_name: "TestJob", exception_class: "RuntimeError", message: "boom", backtrace: ["app/jobs/test_job.rb:10"])
    job = SolidQueue::Job.create!(
      queue_name: "default", class_name: class_name,
      arguments: {}, active_job_id: SecureRandom.uuid
    )
    job.ready_execution&.destroy
    SolidQueue::FailedExecution.create!(
      job: job,
      error: { exception_class: exception_class, message: message, backtrace: backtrace }
    )
  end

  describe "GET /jobs/failed_jobs/errors" do
    it "returns HTTP success" do
      get "/jobs/failed_jobs/errors"
      expect(response).to have_http_status(:ok)
    end

    it "displays the Error Summary heading" do
      get "/jobs/failed_jobs/errors"
      expect(response.body).to include("Error Summary")
    end

    it "shows an empty state when no failed jobs exist" do
      get "/jobs/failed_jobs/errors"
      expect(response.body).to include("No failed jobs")
    end

    it "renders a row for each distinct error class" do
      failed_execution(exception_class: "ArgumentError", message: "bad arg")
      failed_execution(exception_class: "TimeoutError",  message: "timed out")

      get "/jobs/failed_jobs/errors"
      expect(response.body).to include("ArgumentError")
      expect(response.body).to include("TimeoutError")
    end

    it "aggregates multiple failures with the same error class and message" do
      2.times { failed_execution(exception_class: "RuntimeError", message: "boom") }

      get "/jobs/failed_jobs/errors"
      expect(response.body).to include("RuntimeError")
      expect(response.body.scan("RuntimeError").size).to eq(1)
    end

    it "sorts groups by count descending" do
      3.times { failed_execution(exception_class: "FrequentError", message: "often") }
      1.times { failed_execution(exception_class: "RareError",     message: "once") }

      get "/jobs/failed_jobs/errors"
      frequent_pos = response.body.index("FrequentError")
      rare_pos      = response.body.index("RareError")
      expect(frequent_pos).to be < rare_pos
    end

    it "truncates long messages to MESSAGE_LIMIT characters" do
      long_message = "x" * 200
      failed_execution(exception_class: "RuntimeError", message: long_message)

      get "/jobs/failed_jobs/errors"
      expect(response.body).not_to include(long_message)
      expect(response.body).to include("x" * 120)
    end

    it "renders a backtrace inside a details element when present" do
      failed_execution(exception_class: "RuntimeError", message: "boom", backtrace: ["app/jobs/test_job.rb:10"])

      get "/jobs/failed_jobs/errors"
      expect(response.body).to include("<details")
      expect(response.body).to include("app/jobs/test_job.rb:10")
    end

    it "links back to the failed jobs page" do
      get "/jobs/failed_jobs/errors"
      expect(response.body).to include("Failed Jobs")
      expect(response.body).to include("/jobs/failed_jobs")
    end

    describe "authentication" do
      after { SolidQueueWeb.instance_variable_set(:@authenticate, nil) }

      it "allows access when auth block returns truthy" do
        SolidQueueWeb.authenticate { true }
        get "/jobs/failed_jobs/errors"
        expect(response).to have_http_status(:ok)
      end

      it "returns 401 when auth block returns falsy" do
        SolidQueueWeb.authenticate { false }
        get "/jobs/failed_jobs/errors"
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end
