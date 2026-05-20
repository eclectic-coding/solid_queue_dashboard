require "rails_helper"

RSpec.describe "BlockedJobs", type: :request do
  let!(:blocked_job) do
    j = SolidQueue::Job.create!(
      queue_name: "default", class_name: "TestJob",
      arguments: {}.to_json, active_job_id: SecureRandom.uuid
    )
    j.ready_execution&.destroy
    j.update!(concurrency_key: "TestJob/1")
    allow_any_instance_of(SolidQueue::BlockedExecution).to receive(:set_expires_at)
    SolidQueue::BlockedExecution.create!(
      job: j, queue_name: j.queue_name, priority: j.priority, expires_at: 1.hour.from_now
    )
    j
  end

  describe "DELETE /jobs/blocked_jobs" do
    it "discards all blocked jobs and redirects to the dashboard" do
      delete "/jobs/blocked_jobs"
      expect(response).to redirect_to("/jobs/")
      follow_redirect!
      expect(response.body).to include("discarded")
    end

    it "removes the blocked execution" do
      expect { delete "/jobs/blocked_jobs" }.to change(SolidQueue::BlockedExecution, :count).by(-1)
    end

    it "handles failure gracefully" do
      allow(SolidQueue::BlockedExecution).to receive(:discard_all_from_jobs).and_raise(RuntimeError, "boom")
      delete "/jobs/blocked_jobs"
      expect(response).to redirect_to("/jobs/")
      follow_redirect!
      expect(response.body).to include("Could not discard blocked jobs")
    end
  end
end
