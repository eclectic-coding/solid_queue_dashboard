module SolidQueueWeb
  class JobsController < ApplicationController
    STATUSES = %w[ready scheduled claimed blocked failed].freeze
    DISCARDABLE = %w[ready scheduled blocked].freeze

    def index
      @status = params[:status].presence_in(STATUSES) || "ready"
      @queue  = params[:queue].presence

      @jobs = case @status
      when "ready"     then SolidQueue::ReadyExecution.includes(:job)
      when "scheduled" then SolidQueue::ScheduledExecution.includes(:job)
      when "claimed"   then SolidQueue::ClaimedExecution.includes(:job)
      when "blocked"   then SolidQueue::BlockedExecution.includes(:job)
      when "failed"    then SolidQueue::FailedExecution.includes(:job)
      end

      @jobs = @jobs.where(jobs: { queue_name: @queue }) if @queue.present?
      @jobs = @jobs.order(created_at: :desc).limit(100)
    end

    def destroy
      execution = execution_model_for!(params[:status]).find(params[:id])
      execution.discard
      redirect_to jobs_path(status: params[:status], queue: params[:queue]), notice: "Job discarded."
    rescue ArgumentError => e
      redirect_to jobs_path(status: params[:status], queue: params[:queue]), alert: e.message
    rescue => e
      redirect_to jobs_path(status: params[:status], queue: params[:queue]), alert: "Could not discard job: #{e.message}"
    end

    def discard_all
      model = execution_model_for!(params[:status])
      scope = model.includes(:job)
      scope = scope.where(jobs: { queue_name: params[:queue] }) if params[:queue].present?
      jobs = scope.map(&:job)
      model.discard_all_from_jobs(jobs)
      redirect_to jobs_path(status: params[:status], queue: params[:queue]),
        notice: "#{jobs.size} #{"job".pluralize(jobs.size)} discarded."
    rescue ArgumentError => e
      redirect_to jobs_path(status: params[:status], queue: params[:queue]), alert: e.message
    rescue => e
      redirect_to jobs_path(status: params[:status], queue: params[:queue]), alert: "Could not discard jobs: #{e.message}"
    end

    private

    def execution_model_for!(status)
      case status
      when "ready"     then SolidQueue::ReadyExecution
      when "scheduled" then SolidQueue::ScheduledExecution
      when "blocked"   then SolidQueue::BlockedExecution
      else raise ArgumentError, "Cannot discard #{status} jobs from this page."
      end
    end
  end
end
