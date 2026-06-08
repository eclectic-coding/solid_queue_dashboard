module SolidQueueWeb
  class RetryFailedJobsController < ApplicationController
    before_action :set_filter_params

    def create
      executions = params[:id] ? [SolidQueue::FailedExecution.find(params[:id])] : filtered_scope.to_a
      jobs = executions.map(&:job)

      if params[:stagger].present? && executions.size > 1
        interval = STAGGER_INTERVALS[params[:stagger]]
        raise ArgumentError, t("solid_queue_web.flash.invalid_stagger") unless interval
        executions.each_with_index do |execution, i|
          execution.job.update!(scheduled_at: i.zero? ? nil : Time.current + (i * interval))
          execution.retry
        end
      else
        SolidQueue::FailedExecution.retry_all(jobs)
      end
      action = params[:id] ? "failed_job_retried" : "failed_jobs_retried"
      record_audit(action, job_class: jobs.first&.class_name, queue_name: jobs.first&.queue_name, item_count: jobs.size)
      redirect_to failed_jobs_path(queue: @queue, q: @search, period: @period),
        notice: retry_notice(jobs.size)
    rescue ArgumentError => e
      redirect_to failed_jobs_path, alert: e.message
    rescue => e
      redirect_to failed_jobs_path, alert: t("solid_queue_web.flash.cannot_retry_job", error: e.message)
    end

    private

    def retry_notice(count)
      if params[:stagger].present? && count > 1
        t("solid_queue_web.flash.jobs_retried_staggered", count: count, stagger: params[:stagger])
      else
        t("solid_queue_web.flash.jobs_retried", count: count)
      end
    end

    def set_filter_params
      @queue  = params[:queue].presence
      @search = params[:q].presence
      @period = params[:period].presence_in(PERIOD_DURATIONS.keys)
    end

    def filtered_scope
      scope = SolidQueue::FailedExecution.includes(:job)
      scope = scope.references(:job).where(solid_queue_jobs: { queue_name: @queue }) if @queue.present?
      scope = scope.references(:job).where("solid_queue_jobs.class_name LIKE ?", "%#{@search}%") if @search.present?
      scope = scope.references(:job).where("solid_queue_jobs.created_at >= ?", PERIOD_DURATIONS[@period].ago) if @period.present?
      scope
    end
  end
end
