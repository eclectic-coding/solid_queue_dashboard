module SolidQueueWeb
  class FailedJobsController < ApplicationController
    before_action :set_filter_params, only: [ :index, :retry_all, :discard_all ]

    def index
      @pagy, @failed_jobs = pagy(filtered_scope.order(created_at: :desc))
    end

    def retry
      execution = SolidQueue::FailedExecution.find(params[:id])
      execution.retry
      redirect_to failed_jobs_path, notice: "Job queued for retry."
    rescue => e
      redirect_to failed_jobs_path, alert: "Could not retry job: #{e.message}"
    end

    def destroy
      execution = SolidQueue::FailedExecution.find(params[:id])
      execution.discard
      redirect_to failed_jobs_path, notice: "Job discarded."
    rescue => e
      redirect_to failed_jobs_path, alert: "Could not discard job: #{e.message}"
    end

    def retry_all
      jobs = filtered_scope.map(&:job)
      SolidQueue::FailedExecution.retry_all(jobs)
      redirect_to failed_jobs_path(queue: @queue, q: @search, period: @period),
        notice: "#{jobs.size} #{"job".pluralize(jobs.size)} queued for retry."
    end

    def discard_all
      jobs = filtered_scope.map(&:job)
      SolidQueue::FailedExecution.discard_all_from_jobs(jobs)
      redirect_to failed_jobs_path(queue: @queue, q: @search, period: @period),
        notice: "#{jobs.size} #{"job".pluralize(jobs.size)} discarded."
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
