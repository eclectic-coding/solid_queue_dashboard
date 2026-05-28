require "rails_helper"

RSpec.describe "Audit recording", type: :request do
  def last_audit
    SolidQueueWeb::AuditEvent.order(:created_at).last
  end

  describe "job discard" do
    let!(:job) do
      SolidQueue::Job.create!(queue_name: "default", class_name: "MyJob",
                              arguments: {}, active_job_id: SecureRandom.uuid)
    end
    let!(:execution) { job.ready_execution }

    it "records job_discarded when a single job is discarded" do
      expect {
        delete "/jobs/list/#{execution.id}", params: { status: "ready" }
      }.to change(SolidQueueWeb::AuditEvent, :count).by(1)

      expect(last_audit.action).to eq("job_discarded")
      expect(last_audit.job_class).to eq("MyJob")
      expect(last_audit.queue_name).to eq("default")
      expect(last_audit.item_count).to eq(1)
    end

    it "records jobs_discarded for bulk discard" do
      expect {
        post "/jobs/list/discard_all", params: { status: "ready" }
      }.to change(SolidQueueWeb::AuditEvent, :count).by(1)

      expect(last_audit.action).to eq("jobs_discarded")
    end
  end

  describe "failed job retry" do
    let!(:job) do
      SolidQueue::Job.create!(queue_name: "default", class_name: "FailingJob",
                              arguments: {}, active_job_id: SecureRandom.uuid)
    end
    let!(:execution) do
      SolidQueue::FailedExecution.create!(
        job: job,
        error: { exception_class: "RuntimeError", message: "boom", backtrace: [] }
      )
    end

    it "records failed_job_retried on single retry" do
      expect {
        post "/jobs/failed_jobs/#{execution.id}/retry"
      }.to change(SolidQueueWeb::AuditEvent, :count).by(1)

      expect(last_audit.action).to eq("failed_job_retried")
      expect(last_audit.job_class).to eq("FailingJob")
      expect(last_audit.item_count).to eq(1)
    end

    it "records failed_jobs_retried on retry all" do
      expect {
        post "/jobs/failed_jobs/retry_all"
      }.to change(SolidQueueWeb::AuditEvent, :count).by(1)

      expect(last_audit.action).to eq("failed_jobs_retried")
    end
  end

  describe "failed job discard" do
    let!(:job) do
      SolidQueue::Job.create!(queue_name: "default", class_name: "FailingJob",
                              arguments: {}, active_job_id: SecureRandom.uuid)
    end
    let!(:execution) do
      SolidQueue::FailedExecution.create!(
        job: job,
        error: { exception_class: "RuntimeError", message: "boom", backtrace: [] }
      )
    end

    it "records failed_job_discarded on single discard" do
      expect {
        delete "/jobs/failed_jobs/#{execution.id}"
      }.to change(SolidQueueWeb::AuditEvent, :count).by(1)

      expect(last_audit.action).to eq("failed_job_discarded")
    end

    it "records failed_jobs_discarded on discard all" do
      expect {
        post "/jobs/failed_jobs/discard_all"
      }.to change(SolidQueueWeb::AuditEvent, :count).by(1)

      expect(last_audit.action).to eq("failed_jobs_discarded")
    end
  end

  describe "queue pause / resume" do
    before do
      SolidQueue::Job.create!(queue_name: "default", class_name: "TestJob",
                              arguments: {}, active_job_id: SecureRandom.uuid)
    end

    it "records queue_paused when a queue is paused" do
      expect {
        post "/jobs/queues/default/pause"
      }.to change(SolidQueueWeb::AuditEvent, :count).by(1)

      expect(last_audit.action).to eq("queue_paused")
      expect(last_audit.queue_name).to eq("default")
    end

    it "records queue_resumed when a queue is resumed" do
      SolidQueue::Pause.create!(queue_name: "default")
      expect {
        delete "/jobs/queues/default/pause"
      }.to change(SolidQueueWeb::AuditEvent, :count).by(1)

      expect(last_audit.action).to eq("queue_resumed")
      expect(last_audit.queue_name).to eq("default")
    end
  end

  describe "current_actor" do
    after { SolidQueueWeb.instance_variable_set(:@current_actor, nil) }

    it "stores the actor from the current_actor block" do
      SolidQueueWeb.current_actor { "admin@example.com" }
      SolidQueue::Job.create!(queue_name: "default", class_name: "TestJob",
                              arguments: {}, active_job_id: SecureRandom.uuid).tap do |j|
        j.ready_execution
      end
      job    = SolidQueue::Job.last
      exec   = job.ready_execution

      delete "/jobs/list/#{exec.id}", params: { status: "ready" }
      expect(last_audit.actor).to eq("admin@example.com")
    end

    it "stores nil actor when current_actor is not configured" do
      SolidQueue::Job.create!(queue_name: "default", class_name: "TestJob",
                              arguments: {}, active_job_id: SecureRandom.uuid).tap do |j|
        j.ready_execution
      end
      job  = SolidQueue::Job.last
      exec = job.ready_execution

      delete "/jobs/list/#{exec.id}", params: { status: "ready" }
      expect(last_audit.actor).to be_nil
    end
  end
end
