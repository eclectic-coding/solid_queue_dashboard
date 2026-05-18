module SolidQueueDashboard
  class FailedJobsController < ApplicationController
    def index
      @failed_jobs = SolidQueue::FailedExecution
        .includes(:job)
        .order(created_at: :desc)
        .limit(100)
    end
  end
end
