module SolidQueueWeb
  class ScheduledJobsController < ApplicationController
    def create
      @period   = params[:period].presence_in(PERIOD_DURATIONS.keys)
      past_time = 1.second.ago

      scope = SolidQueue::ScheduledExecution.joins(:job)
      scope = scope.where("solid_queue_jobs.created_at >= ?", PERIOD_DURATIONS[@period].ago) if @period.present?

      job_ids = scope.pluck("solid_queue_jobs.id")
      count   = job_ids.size

      SolidQueue::ScheduledExecution.where(job_id: job_ids).update_all(scheduled_at: past_time)
      SolidQueue::Job.where(id: job_ids).update_all(scheduled_at: past_time)

      redirect_to jobs_path(status: "scheduled", period: @period),
        notice: "#{count} #{"job".pluralize(count)} scheduled to run immediately."
    rescue => e
      redirect_to jobs_path(status: "scheduled", period: @period),
        alert: "Could not run jobs: #{e.message}"
    end

    def update
      @execution = SolidQueue::ScheduledExecution.find(params[:id])
      @period    = params[:period].presence_in(PERIOD_DURATIONS.keys)
      @run_now   = params[:offset] == "now"

      new_time = if @run_now
        1.second.ago
      elsif PERIOD_DURATIONS.key?(params[:offset])
        @execution.scheduled_at + PERIOD_DURATIONS[params[:offset]]
      else
        raise ArgumentError, "Invalid offset."
      end

      @execution.update!(scheduled_at: new_time)
      @execution.job.update!(scheduled_at: new_time)

      respond_to do |format|
        format.turbo_stream
        format.html do
          notice = @run_now ? "Job scheduled to run immediately." : "Job rescheduled by +#{params[:offset]}."
          redirect_to jobs_path(status: "scheduled", period: @period), notice: notice
        end
      end
    rescue ArgumentError => e
      redirect_to jobs_path(status: "scheduled"), alert: e.message
    rescue => e
      redirect_to jobs_path(status: "scheduled"), alert: "Could not reschedule job: #{e.message}"
    end
  end
end
