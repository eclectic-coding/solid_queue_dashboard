module SolidQueueWeb
  class QueueStats
    attr_reader :completed_24h, :failed_24h, :oldest_ready, :failure_sparklines

    def initialize(queues)
      @queues = queues
      @now    = Time.current
      compute
    end

    private

    def compute
      @completed_24h = SolidQueue::Job
        .where(finished_at: 24.hours.ago..@now)
        .group(:queue_name)
        .count

      @failed_24h = SolidQueue::FailedExecution
        .joins(:job)
        .where(created_at: 24.hours.ago..@now)
        .group("solid_queue_jobs.queue_name")
        .count

      @oldest_ready = SolidQueue::ReadyExecution
        .joins(:job)
        .group("solid_queue_jobs.queue_name")
        .minimum("solid_queue_jobs.created_at")

      failed_raw = SolidQueue::FailedExecution
        .joins(:job)
        .where(created_at: 12.hours.ago..@now)
        .pluck("solid_queue_jobs.queue_name", "solid_queue_failed_executions.created_at")
      done_raw = SolidQueue::Job
        .where(finished_at: 12.hours.ago..@now)
        .pluck(:queue_name, :finished_at)

      @failure_sparklines = @queues.each_with_object({}) do |queue, h|
        failed_times = failed_raw.filter_map { |q, t| t if q == queue.name }
        done_times   = done_raw.filter_map   { |q, t| t if q == queue.name }
        h[queue.name] = 12.times.map do |i|
          from = (12 - i).hours.ago
          to   = i == 11 ? @now : (11 - i).hours.ago
          f = failed_times.count { |t| t >= from && t < to }
          d = done_times.count   { |t| t >= from && t < to }
          total = f + d
          total > 0 ? (f.to_f / total * 100).round : nil
        end
      end
    end
  end
end
