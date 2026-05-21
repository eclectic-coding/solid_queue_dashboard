module SolidQueueWeb
  class MetricsController < ApplicationController
    def index
      now = Time.current
      processes = SolidQueue::Process.all.to_a
      threshold = SolidQueue.process_alive_threshold.ago

      queues = SolidQueue::Queue.all.sort_by(&:name)
      queue_depths = SolidQueue::ReadyExecution
        .joins(:job)
        .group("solid_queue_jobs.queue_name")
        .count

      finished_times = SolidQueue::Job.where(finished_at: 24.hours.ago..now).pluck(:finished_at)

      payload = {
        generated_at: now.iso8601,
        jobs: {
          ready:     SolidQueue::ReadyExecution.count,
          scheduled: SolidQueue::ScheduledExecution.count,
          claimed:   SolidQueue::ClaimedExecution.count,
          blocked:   SolidQueue::BlockedExecution.count,
          failed:    SolidQueue::FailedExecution.count
        },
        throughput: {
          completed_1h:  finished_times.count { |t| t >= 1.hour.ago },
          completed_24h: finished_times.size
        },
        queues: queues.map { |q|
          { name: q.name, depth: queue_depths[q.name] || 0, paused: q.paused? }
        },
        processes: {
          total:   processes.size,
          healthy: processes.count { |p| p.last_heartbeat_at >= threshold },
          stale:   processes.count { |p| p.last_heartbeat_at < threshold },
          by_kind: processes.group_by(&:kind).transform_values(&:size)
        }
      }

      slow_threshold = SolidQueueWeb.slow_job_threshold
      if slow_threshold
        payload[:slow_jobs] = SolidQueue::ClaimedExecution.where("created_at <= ?", slow_threshold.ago).count
      end

      render json: payload
    end
  end
end
