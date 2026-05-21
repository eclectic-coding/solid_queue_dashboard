module SolidQueueWeb
  class ScheduledJobsController < ApplicationController
    OFFSETS = { "1h" => 1.hour, "24h" => 24.hours, "7d" => 7.days }.freeze

    def update
      @execution = SolidQueue::ScheduledExecution.find(params[:id])
      @period    = params[:period].presence_in(PERIOD_DURATIONS.keys)
      @run_now   = params[:offset] == "now"

      new_time = if @run_now
        1.second.ago
      elsif OFFSETS.key?(params[:offset])
        @execution.scheduled_at + OFFSETS[params[:offset]]
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
