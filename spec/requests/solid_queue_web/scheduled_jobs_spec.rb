require "rails_helper"

RSpec.describe "ScheduledJobs", type: :request do
  let!(:job) do
    SolidQueue::Job.create!(
      queue_name: "default",
      class_name: "TestJob",
      arguments: {},
      active_job_id: SecureRandom.uuid,
      scheduled_at: 2.hours.from_now
    )
  end

  let(:execution) { job.scheduled_execution }

  describe "PATCH /scheduled_jobs/:id" do
    context "with offset=now" do
      it "sets scheduled_at to the past and redirects" do
        patch "/jobs/scheduled_jobs/#{execution.id}", params: { offset: "now" }
        expect(response).to redirect_to("/jobs/list?status=scheduled")
        execution.reload
        expect(execution.scheduled_at).to be <= Time.current
      end

      it "also updates the job's scheduled_at" do
        patch "/jobs/scheduled_jobs/#{execution.id}", params: { offset: "now" }
        job.reload
        expect(job.scheduled_at).to be <= Time.current
      end

      it "removes the row via turbo stream" do
        patch "/jobs/scheduled_jobs/#{execution.id}",
          params: { offset: "now" },
          headers: { "Accept" => "text/vnd.turbo-stream.html, text/html" }
        expect(response.content_type).to include("text/vnd.turbo-stream.html")
        expect(response.body).to include("execution_#{execution.id}")
        expect(response.body).to include("remove")
      end
    end

    context "with offset=1h" do
      it "postpones scheduled_at by 1 hour and redirects" do
        original = execution.scheduled_at
        patch "/jobs/scheduled_jobs/#{execution.id}", params: { offset: "1h" }
        expect(response).to redirect_to("/jobs/list?status=scheduled")
        execution.reload
        expect(execution.scheduled_at).to be_within(5.seconds).of(original + 1.hour)
      end

      it "updates the cell via turbo stream" do
        patch "/jobs/scheduled_jobs/#{execution.id}",
          params: { offset: "1h" },
          headers: { "Accept" => "text/vnd.turbo-stream.html, text/html" }
        expect(response.content_type).to include("text/vnd.turbo-stream.html")
        expect(response.body).to include("scheduled_at_#{execution.id}")
        expect(response.body).to include("replace")
      end
    end

    context "with offset=24h" do
      it "postpones scheduled_at by 24 hours" do
        original = execution.scheduled_at
        patch "/jobs/scheduled_jobs/#{execution.id}", params: { offset: "24h" }
        execution.reload
        expect(execution.scheduled_at).to be_within(5.seconds).of(original + 24.hours)
      end
    end

    context "with offset=7d" do
      it "postpones scheduled_at by 7 days" do
        original = execution.scheduled_at
        patch "/jobs/scheduled_jobs/#{execution.id}", params: { offset: "7d" }
        execution.reload
        expect(execution.scheduled_at).to be_within(5.seconds).of(original + 7.days)
      end
    end

    context "with an invalid offset" do
      it "redirects with an alert" do
        patch "/jobs/scheduled_jobs/#{execution.id}", params: { offset: "bogus" }
        expect(response).to redirect_to("/jobs/list?status=scheduled")
        follow_redirect!
        expect(response.body).to include("Invalid offset")
      end

      it "does not modify scheduled_at" do
        original = execution.scheduled_at
        patch "/jobs/scheduled_jobs/#{execution.id}", params: { offset: "bogus" }
        execution.reload
        expect(execution.scheduled_at).to be_within(1.second).of(original)
      end
    end

    context "with a missing execution" do
      it "redirects with an alert" do
        patch "/jobs/scheduled_jobs/0", params: { offset: "now" }
        expect(response).to redirect_to("/jobs/list?status=scheduled")
        follow_redirect!
        expect(response.body).to include("Could not reschedule job")
      end
    end

    context "when period param is present" do
      it "preserves period in the redirect" do
        patch "/jobs/scheduled_jobs/#{execution.id}", params: { offset: "now", period: "24h" }
        expect(response).to redirect_to("/jobs/list?period=24h&status=scheduled")
      end
    end
  end
end