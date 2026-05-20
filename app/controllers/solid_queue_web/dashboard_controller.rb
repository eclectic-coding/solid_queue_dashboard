module SolidQueueWeb
  class DashboardController < ApplicationController
    def index
      @stats = {
        ready:     SolidQueue::ReadyExecution.count,
        scheduled: SolidQueue::ScheduledExecution.count,
        claimed:   SolidQueue::ClaimedExecution.count,
        failed:    SolidQueue::FailedExecution.count,
        blocked:   SolidQueue::BlockedExecution.count,
        queues:    SolidQueue::Job.select(:queue_name).distinct.count,
        processes: SolidQueue::Process.count,
        recurring: SolidQueue::RecurringTask.count
      }

      now = Time.current
      finished_times = SolidQueue::Job.where(finished_at: 24.hours.ago..now).pluck(:finished_at)
      @throughput = {
        completed_1h:  finished_times.count { |t| t >= 1.hour.ago },
        completed_24h: finished_times.size
      }
      @sparkline = 12.times.map do |i|
        from = (12 - i).hours.ago
        to   = i == 11 ? now : (11 - i).hours.ago
        finished_times.count { |t| t >= from && t < to }
      end
    end

    def retry_all_failed
      jobs = SolidQueue::FailedExecution.includes(:job).map(&:job)
      SolidQueue::FailedExecution.retry_all(jobs)
      redirect_to root_path, notice: "#{jobs.size} failed #{"job".pluralize(jobs.size)} queued for retry."
    rescue => e
      redirect_to root_path, alert: "Could not retry failed jobs: #{e.message}"
    end

    def discard_all_blocked
      jobs = SolidQueue::BlockedExecution.includes(:job).map(&:job)
      SolidQueue::BlockedExecution.discard_all_from_jobs(jobs)
      redirect_to root_path, notice: "#{jobs.size} blocked #{"job".pluralize(jobs.size)} discarded."
    rescue => e
      redirect_to root_path, alert: "Could not discard blocked jobs: #{e.message}"
    end
  end
end
