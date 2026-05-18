module SolidQueueDashboard
  class FailedJobsController < ApplicationController
    def index
      @failed_jobs = SolidQueue::FailedExecution
        .includes(:job)
        .order(created_at: :desc)
        .page(params[:page]).per(50)
    end

    def retry
      execution = SolidQueue::FailedExecution.find(params[:id])
      execution.retry
      redirect_to failed_jobs_path, notice: "Job queued for retry."
    end

    def discard
      execution = SolidQueue::FailedExecution.find(params[:id])
      execution.discard
      redirect_to failed_jobs_path, notice: "Job discarded."
    end

    def discard_all
      SolidQueue::FailedExecution.discard_all
      redirect_to failed_jobs_path, notice: "All failed jobs discarded."
    end
  end
end