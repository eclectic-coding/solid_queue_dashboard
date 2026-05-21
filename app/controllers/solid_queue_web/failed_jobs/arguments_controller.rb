module SolidQueueWeb
  class FailedJobs::ArgumentsController < ApplicationController
    def update
      execution = SolidQueue::FailedExecution.find(params[:failed_job_id])
      new_arguments = JSON.parse(params[:arguments])
      execution.job.update!(arguments: new_arguments)
      execution.retry
      redirect_to failed_jobs_path, notice: "Job arguments updated and queued for retry."
    rescue JSON::ParserError
      redirect_to job_path(execution.job), alert: "Invalid JSON: could not parse arguments."
    rescue => e
      redirect_to failed_jobs_path, alert: "Could not update job: #{e.message}"
    end
  end
end
