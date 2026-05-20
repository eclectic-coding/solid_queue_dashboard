module SolidQueueWeb
  class RetryFailedJobsController < ApplicationController
    before_action :set_filter_params

    def create
      executions = params[:id] ? [SolidQueue::FailedExecution.find(params[:id])] : filtered_scope.to_a
      jobs = executions.map(&:job)
      SolidQueue::FailedExecution.retry_all(jobs)
      redirect_to failed_jobs_path(queue: @queue, q: @search, period: @period),
        notice: "#{jobs.size} #{"job".pluralize(jobs.size)} queued for retry."
    rescue => e
      redirect_to failed_jobs_path, alert: "Could not retry job: #{e.message}"
    end

    private

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