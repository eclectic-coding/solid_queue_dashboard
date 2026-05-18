module SolidQueueWeb
  class FailedJobsController < ApplicationController
    def index
      @failed_jobs = SolidQueue::FailedExecution
        .includes(:job)
        .order(created_at: :desc)
        .limit(100)
    end

    def retry
      execution = SolidQueue::FailedExecution.find(params[:id])
      execution.retry
      redirect_to failed_jobs_path, notice: "Job queued for retry."
    rescue => e
      redirect_to failed_jobs_path, alert: "Could not retry job: #{e.message}"
    end

    def destroy
      execution = SolidQueue::FailedExecution.find(params[:id])
      execution.discard
      redirect_to failed_jobs_path, notice: "Job discarded."
    rescue => e
      redirect_to failed_jobs_path, alert: "Could not discard job: #{e.message}"
    end

    def retry_all
      executions = SolidQueue::FailedExecution.includes(:job).to_a
      jobs = executions.map(&:job)
      SolidQueue::FailedExecution.retry_all(jobs)
      redirect_to failed_jobs_path, notice: "#{jobs.size} #{"job".pluralize(jobs.size)} queued for retry."
    end

    def discard_all
      count = SolidQueue::FailedExecution.count
      SolidQueue::FailedExecution.discard_all_in_batches
      redirect_to failed_jobs_path, notice: "#{count} #{"job".pluralize(count)} discarded."
    end
  end
end
