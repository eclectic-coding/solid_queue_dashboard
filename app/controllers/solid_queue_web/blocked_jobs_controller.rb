module SolidQueueWeb
  class BlockedJobsController < ApplicationController
    def destroy
      jobs = SolidQueue::BlockedExecution.includes(:job).map(&:job)
      SolidQueue::BlockedExecution.discard_all_from_jobs(jobs)
      redirect_to root_path, notice: "#{jobs.size} blocked #{"job".pluralize(jobs.size)} discarded."
    rescue => e
      redirect_to root_path, alert: "Could not discard blocked jobs: #{e.message}"
    end
  end
end
