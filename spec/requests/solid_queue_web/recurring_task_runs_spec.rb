require "rails_helper"

RSpec.describe "RecurringTasks::Runs", type: :request do
  let!(:task) do
    SolidQueue::RecurringTask.create!(
      key: "cleanup-task",
      schedule: "0 2 * * *",
      command: "CleanupJob.perform_later"
    )
  end

  before do
    allow_any_instance_of(SolidQueue::RecurringTask).to receive(:enqueue)
      .with(at: instance_of(ActiveSupport::TimeWithZone))
      .and_return(double("job", job_id: SecureRandom.uuid))
  end

  describe "POST /jobs/recurring_tasks/:key/run" do
    it "redirects to the recurring tasks page" do
      post "/jobs/recurring_tasks/cleanup-task/run"
      expect(response).to redirect_to("/jobs/recurring_tasks")
    end

    it "shows a success notice" do
      post "/jobs/recurring_tasks/cleanup-task/run"
      follow_redirect!
      expect(response.body).to include("queued for immediate execution")
    end

    it "includes the task key in the notice" do
      post "/jobs/recurring_tasks/cleanup-task/run"
      follow_redirect!
      expect(response.body).to include("cleanup-task")
    end

    it "renders a Run Now button on the index page" do
      get "/jobs/recurring_tasks"
      expect(response.body).to include("Run Now")
    end

    it "returns 404 redirect for an unknown key" do
      post "/jobs/recurring_tasks/nonexistent-task/run"
      expect(response).to redirect_to("/jobs/recurring_tasks")
      follow_redirect!
      expect(response.body).to include("Recurring task not found")
    end

    it "shows an alert when enqueue returns false" do
      allow_any_instance_of(SolidQueue::RecurringTask).to receive(:enqueue).and_return(false)
      post "/jobs/recurring_tasks/cleanup-task/run"
      follow_redirect!
      expect(response.body).to include("Could not enqueue")
    end

    it "handles unexpected errors gracefully" do
      allow_any_instance_of(SolidQueue::RecurringTask).to receive(:enqueue).and_raise(RuntimeError, "boom")
      post "/jobs/recurring_tasks/cleanup-task/run"
      expect(response).to redirect_to("/jobs/recurring_tasks")
      follow_redirect!
      expect(response.body).to include("Could not run task")
    end
  end
end
