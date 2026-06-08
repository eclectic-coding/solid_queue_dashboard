module SolidQueueWeb
  module FailedJobs
    class SelectionsController < ApplicationController
      def create
        ids = Array(params[:ids]).map(&:to_i).reject(&:zero?)
        executions = SolidQueue::FailedExecution.where(id: ids)
        jobs = executions.includes(:job).map(&:job)
        SolidQueue::FailedExecution.retry_all(jobs)
        record_audit("failed_jobs_retried", item_count: jobs.size)
        redirect_to failed_jobs_path,
          notice: t("solid_queue_web.flash.jobs_retried", count: jobs.size)
      rescue => e
        redirect_to failed_jobs_path, alert: t("solid_queue_web.flash.cannot_retry_jobs", error: e.message)
      end

      def destroy
        ids = Array(params[:ids]).map(&:to_i).reject(&:zero?)
        executions = SolidQueue::FailedExecution.where(id: ids)
        jobs = executions.includes(:job).map(&:job)
        SolidQueue::FailedExecution.discard_all_from_jobs(jobs)
        record_audit("failed_jobs_discarded", item_count: jobs.size)
        redirect_to failed_jobs_path,
          notice: t("solid_queue_web.flash.jobs_discarded", count: jobs.size)
      rescue => e
        redirect_to failed_jobs_path, alert: t("solid_queue_web.flash.cannot_discard_jobs", error: e.message)
      end
    end
  end
end
