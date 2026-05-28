module SolidQueueWeb
  module Jobs
    class SelectionsController < ApplicationController
      def destroy
        status = params[:status]
        period = params[:period].presence_in(PERIOD_DURATIONS.keys)
        raise ArgumentError, "Cannot discard #{status} jobs." unless Job::DISCARDABLE.include?(status)
        model = Job::EXECUTION_MODELS[status]
        ids = Array(params[:ids]).map(&:to_i).reject(&:zero?)
        jobs = model.where(id: ids).includes(:job).map(&:job)
        model.discard_all_from_jobs(jobs)
        record_audit("jobs_discarded", item_count: jobs.size)
        redirect_to jobs_path(status: status, period: period),
          notice: "#{jobs.size} #{"job".pluralize(jobs.size)} discarded."
      rescue ArgumentError => e
        redirect_to jobs_path(status: status), alert: e.message
      rescue => e
        redirect_to jobs_path(status: status), alert: "Could not discard jobs: #{e.message}"
      end
    end
  end
end
