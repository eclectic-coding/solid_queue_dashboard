module SolidQueueWeb
  class QueuesController < ApplicationController
    def index
      @queues = SolidQueue::Queue.all.sort_by(&:name)
      stats = QueueStats.new(@queues)
      @completed_24h      = stats.completed_24h
      @failed_24h         = stats.failed_24h
      @oldest_ready       = stats.oldest_ready
      @failure_sparklines = stats.failure_sparklines
      @queue_sizes        = SolidQueue::ReadyExecution
        .joins(:job)
        .group("solid_queue_jobs.queue_name")
        .count
      @paused_queue_names = SolidQueue::Pause.pluck(:queue_name).to_set
    end
  end
end
