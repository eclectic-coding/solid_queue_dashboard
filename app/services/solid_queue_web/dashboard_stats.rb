module SolidQueueWeb
  class DashboardStats
    attr_reader :counts, :throughput, :sparkline, :depth_sparkline, :slow_jobs_count

    def initialize
      @now = Time.current
      compute
    end

    private

    def compute
      @counts = {
        ready:     SolidQueue::ReadyExecution.count,
        scheduled: SolidQueue::ScheduledExecution.count,
        claimed:   SolidQueue::ClaimedExecution.count,
        failed:    SolidQueue::FailedExecution.count,
        blocked:   SolidQueue::BlockedExecution.count,
        queues:    SolidQueue::Job.select(:queue_name).distinct.count,
        processes: SolidQueue::Process.count,
        recurring: SolidQueue::RecurringTask.count
      }

      finished_times = SolidQueue::Job.where(finished_at: 24.hours.ago..@now).pluck(:finished_at)
      @throughput = {
        completed_1h:  finished_times.count { |t| t >= 1.hour.ago },
        completed_24h: finished_times.size
      }
      @sparkline = 12.times.map do |i|
        from = (12 - i).hours.ago
        to   = i == 11 ? @now : (11 - i).hours.ago
        finished_times.count { |t| t >= from && t < to }
      end

      threshold = SolidQueueWeb.slow_job_threshold
      @slow_jobs_count = threshold ? SolidQueue::ClaimedExecution.where("created_at <= ?", threshold.ago).count : 0

      job_timestamps = SolidQueue::Job
        .where("created_at >= ? OR finished_at IS NULL", 72.hours.ago)
        .pluck(:created_at, :finished_at)
      @depth_sparkline = 12.times.map do |i|
        t = i == 11 ? @now : (12 - i).hours.ago
        job_timestamps.count { |created, finished| created <= t && (finished.nil? || finished > t) }
      end
    end
  end
end
