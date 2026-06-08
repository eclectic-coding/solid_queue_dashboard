module SolidQueueWeb
  class FailedJobs::ArgumentsController < ApplicationController
    def update
      execution = SolidQueue::FailedExecution.find(params[:failed_job_id])
      new_arguments = JSON.parse(params[:arguments])
      execution.job.update!(arguments: new_arguments)
      execution.retry
      redirect_to failed_jobs_path, notice: t("solid_queue_web.flash.arguments_updated")
    rescue JSON::ParserError
      redirect_to job_path(execution.job), alert: t("solid_queue_web.flash.invalid_json")
    rescue => e
      redirect_to failed_jobs_path, alert: t("solid_queue_web.flash.cannot_update_job", error: e.message)
    end
  end
end
