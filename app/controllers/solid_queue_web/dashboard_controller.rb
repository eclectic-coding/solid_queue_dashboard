module SolidQueueWeb
  class DashboardController < ApplicationController
    def index
      stats            = DashboardStats.new
      @stats           = stats.stats
      @throughput      = stats.throughput
      @sparkline       = stats.sparkline
      @depth_sparkline = stats.depth_sparkline
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
