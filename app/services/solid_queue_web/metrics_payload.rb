module SolidQueueWeb
  class MetricsPayload
    def initialize
      @now = Time.current
    end

    def to_h
      payload = {
        generated_at: @now.iso8601,
        jobs:         job_counts,
        throughput:   throughput,
        queues:       queue_list,
        processes:    process_summary
      }
      slow = slow_jobs_count
      payload[:slow_jobs] = slow unless slow.nil?
      payload
    end

    private

    def job_counts
      {
        ready:     SolidQueue::ReadyExecution.count,
        scheduled: SolidQueue::ScheduledExecution.count,
        claimed:   SolidQueue::ClaimedExecution.count,
        blocked:   SolidQueue::BlockedExecution.count,
        failed:    SolidQueue::FailedExecution.count
      }
    end

    def throughput
      finished_times = SolidQueue::Job.where(finished_at: 24.hours.ago..@now).pluck(:finished_at)
      {
        completed_1h:  finished_times.count { |t| t >= 1.hour.ago },
        completed_24h: finished_times.size
      }
    end

    def queue_list
      depths = SolidQueue::ReadyExecution
        .joins(:job)
        .group("solid_queue_jobs.queue_name")
        .count
      SolidQueue::Queue.all.sort_by(&:name).map do |q|
        { name: q.name, depth: depths[q.name] || 0, paused: q.paused? }
      end
    end

    def process_summary
      processes = SolidQueue::Process.all.to_a
      threshold = SolidQueue.process_alive_threshold.ago
      {
        total:   processes.size,
        healthy: processes.count { |p| p.last_heartbeat_at >= threshold },
        stale:   processes.count { |p| p.last_heartbeat_at < threshold },
        by_kind: processes.group_by(&:kind).transform_values(&:size)
      }
    end

    def slow_jobs_count
      threshold = SolidQueueWeb.slow_job_threshold
      SolidQueue::ClaimedExecution.where("created_at <= ?", threshold.ago).count if threshold
    end
  end
end
