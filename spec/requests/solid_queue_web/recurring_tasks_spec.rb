require "rails_helper"

RSpec.describe "RecurringTasks", type: :request do
  let!(:recurring_task) do
    SolidQueue::RecurringTask.create!(
      key: "cleanup-task",
      schedule: "0 2 * * *",
      command: "CleanupJob.perform_later",
      queue_name: "default",
      description: "Nightly cleanup"
    )
  end

  let!(:dynamic_task) do
    SolidQueue::RecurringTask.create!(
      key: "dynamic-report-task",
      schedule: "0 8 * * 1",
      command: "ReportJob.perform_later",
      static: false
    )
  end

  describe "GET /jobs/recurring_tasks" do
    it "returns HTTP success" do
      get "/jobs/recurring_tasks"
      expect(response).to have_http_status(:ok)
    end

    it "displays task keys" do
      get "/jobs/recurring_tasks"
      expect(response.body).to include("cleanup-task")
      expect(response.body).to include("dynamic-report-task")
    end

    it "displays the schedule" do
      get "/jobs/recurring_tasks"
      expect(response.body).to include("0 2 * * *")
    end

    it "displays the description" do
      get "/jobs/recurring_tasks"
      expect(response.body).to include("Nightly cleanup")
    end

    it "distinguishes static and dynamic tasks" do
      get "/jobs/recurring_tasks"
      expect(response.body).to include("Static")
      expect(response.body).to include("Dynamic")
    end

    it "shows empty state when no tasks exist" do
      SolidQueue::RecurringTask.delete_all
      get "/jobs/recurring_tasks"
      expect(response.body).to include("No recurring tasks")
    end
  end
end