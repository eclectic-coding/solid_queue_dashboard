module SolidQueueWeb
  module FailedJobs
    class SelectionsController < ApplicationController
      def create
        ids = Array(params[:ids]).map(&:to_i).reject(&:zero?)
        executions = SolidQueue::FailedExecution.where(id: ids)
        jobs = executions.includes(:job).map(&:job)
        SolidQueue::FailedExecution.retry_all(jobs)
        redirect_to failed_jobs_path,
          notice: "#{jobs.size} #{"job".pluralize(jobs.size)} queued for retry."
      rescue => e
        redirect_to failed_jobs_path, alert: "Could not retry jobs: #{e.message}"
      end

      def destroy
        ids = Array(params[:ids]).map(&:to_i).reject(&:zero?)
        executions = SolidQueue::FailedExecution.where(id: ids)
        jobs = executions.includes(:job).map(&:job)
        SolidQueue::FailedExecution.discard_all_from_jobs(jobs)
        redirect_to failed_jobs_path,
          notice: "#{jobs.size} #{"job".pluralize(jobs.size)} discarded."
      rescue => e
        redirect_to failed_jobs_path, alert: "Could not discard jobs: #{e.message}"
      end
    end
  end
end
