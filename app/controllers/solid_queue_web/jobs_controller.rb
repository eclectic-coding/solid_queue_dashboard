module SolidQueueWeb
  class JobsController < ApplicationController
    STATUSES = %w[ready scheduled claimed blocked failed].freeze
    DISCARDABLE = %w[ready scheduled blocked].freeze

    before_action :set_status_and_queue, only: [ :destroy, :discard_all ]

    EXECUTION_MODELS = {
      "ready"     => SolidQueue::ReadyExecution,
      "scheduled" => SolidQueue::ScheduledExecution,
      "claimed"   => SolidQueue::ClaimedExecution,
      "blocked"   => SolidQueue::BlockedExecution,
      "failed"    => SolidQueue::FailedExecution
    }.freeze

    def index
      @status = params[:status].presence_in(STATUSES) || "ready"
      @queue  = params[:queue].presence
      @jobs   = EXECUTION_MODELS[@status].includes(:job)
      @jobs   = @jobs.where(jobs: { queue_name: @queue }) if @queue.present?
      @pagy, @jobs = pagy(@jobs.order(created_at: :desc))
    end

    def show
      @job = SolidQueue::Job
        .includes(:ready_execution, :scheduled_execution, :claimed_execution, :blocked_execution, :failed_execution)
        .find(params[:id])
      @failed_execution = @job.failed_execution
      @execution_status = derive_status(@job)
    end

    def destroy
      model = execution_model_for!(@status)
      @execution = model.find(params[:id])
      @execution.discard
      @remaining_count = filtered_scope(model).count
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to jobs_path(status: @status, queue: @queue), notice: "Job discarded." }
      end
    rescue ArgumentError => e
      redirect_to jobs_path(status: @status, queue: @queue), alert: e.message
    rescue => e
      redirect_to jobs_path(status: @status, queue: @queue), alert: "Could not discard job: #{e.message}"
    end

    def discard_all
      model = execution_model_for!(@status)
      jobs = filtered_scope(model).map(&:job)
      model.discard_all_from_jobs(jobs)
      redirect_to jobs_path(status: @status, queue: @queue),
        notice: "#{jobs.size} #{"job".pluralize(jobs.size)} discarded."
    rescue ArgumentError => e
      redirect_to jobs_path(status: @status, queue: @queue), alert: e.message
    rescue => e
      redirect_to jobs_path(status: @status, queue: @queue), alert: "Could not discard jobs: #{e.message}"
    end

    private

    def derive_status(job)
      return "failed"    if job.failed_execution.present?
      return "claimed"   if job.claimed_execution.present?
      return "blocked"   if job.blocked_execution.present?
      return "ready"     if job.ready_execution.present?
      return "scheduled" if job.scheduled_execution.present?
      "finished"
    end

    def set_status_and_queue
      @status = params[:status]
      @queue  = params[:queue].presence
    end

    def filtered_scope(model)
      scope = model.includes(:job)
      @queue.present? ? scope.where(jobs: { queue_name: @queue }) : scope
    end

    def execution_model_for!(status)
      raise ArgumentError, "Cannot discard #{status} jobs from this page." unless DISCARDABLE.include?(status)
      EXECUTION_MODELS[status]
    end
  end
end
