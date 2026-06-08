module SolidQueueWeb
  module Jobs
    class SelectionsController < ApplicationController
      def destroy
        status = params[:status]
        period = params[:period].presence_in(PERIOD_DURATIONS.keys)
        raise ArgumentError, t("solid_queue_web.flash.cannot_discard", status: status) unless Job::DISCARDABLE.include?(status)
        model = Job::EXECUTION_MODELS[status]
        ids = Array(params[:ids]).map(&:to_i).reject(&:zero?)
        jobs = model.where(id: ids).includes(:job).map(&:job)
        model.discard_all_from_jobs(jobs)
        record_audit("jobs_discarded", item_count: jobs.size)
        redirect_to jobs_path(status: status, period: period),
          notice: t("solid_queue_web.flash.jobs_discarded", count: jobs.size)
      rescue ArgumentError => e
        redirect_to jobs_path(status: status), alert: e.message
      rescue => e
        redirect_to jobs_path(status: status), alert: t("solid_queue_web.flash.cannot_discard_jobs", error: e.message)
      end
    end
  end
end
