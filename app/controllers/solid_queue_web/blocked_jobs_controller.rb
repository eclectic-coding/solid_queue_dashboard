module SolidQueueWeb
  class BlockedJobsController < ApplicationController
    def destroy
      jobs = SolidQueue::BlockedExecution.includes(:job).map(&:job)
      SolidQueue::BlockedExecution.discard_all_from_jobs(jobs)
      redirect_to root_path, notice: t("solid_queue_web.flash.blocked_jobs_discarded", count: jobs.size)
    rescue => e
      redirect_to root_path, alert: t("solid_queue_web.flash.cannot_discard_blocked_jobs", error: e.message)
    end
  end
end
