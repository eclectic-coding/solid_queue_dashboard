module SolidQueueWeb
  class JobsController < ApplicationController
    before_action :set_status, only: [ :destroy, :discard_all ]

    def index
      @status = params[:status].presence_in(Job::STATUSES) || "ready"
      @search = params[:q].presence
      @jobs   = Job::EXECUTION_MODELS[@status].includes(:job)
      @jobs   = @jobs.references(:job).where("solid_queue_jobs.class_name LIKE ?", "%#{@search}%") if @search.present?
      @pagy, @jobs = pagy(@jobs.order(created_at: :desc))
    end

    def show
      @job = SolidQueue::Job
        .includes(:ready_execution, :scheduled_execution, :claimed_execution, :blocked_execution, :failed_execution)
        .find(params[:id])
      @failed_execution = @job.failed_execution
      @blocked_execution = @job.blocked_execution
      @execution_status = derive_status(@job)
    end

    def destroy
      model = execution_model_for!(@status)
      @execution = model.find(params[:id])
      @execution.discard
      @remaining_count = filtered_scope(model).count
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to jobs_path(status: @status), notice: "Job discarded." }
      end
    rescue ArgumentError => e
      redirect_to jobs_path(status: @status), alert: e.message
    rescue => e
      redirect_to jobs_path(status: @status), alert: "Could not discard job: #{e.message}"
    end

    def discard_all
      model = execution_model_for!(@status)
      jobs = filtered_scope(model).map(&:job)
      model.discard_all_from_jobs(jobs)
      redirect_to jobs_path(status: @status),
        notice: "#{jobs.size} #{"job".pluralize(jobs.size)} discarded."
    rescue ArgumentError => e
      redirect_to jobs_path(status: @status), alert: e.message
    rescue => e
      redirect_to jobs_path(status: @status), alert: "Could not discard jobs: #{e.message}"
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

    def set_status
      @status = params[:status]
    end

    def filtered_scope(model)
      model.includes(:job)
    end

    def execution_model_for!(status)
      raise ArgumentError, "Cannot discard #{status} jobs from this page." unless Job::DISCARDABLE.include?(status)
      Job::EXECUTION_MODELS[status]
    end
  end
end
