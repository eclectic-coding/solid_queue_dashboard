module SolidQueueWeb
  class QueuesController < ApplicationController
    def index
      @queues = SolidQueue::Queue.all.sort_by(&:name)
      stats = QueueStats.new(@queues)
      @completed_24h      = stats.completed_24h
      @failed_24h         = stats.failed_24h
      @oldest_ready       = stats.oldest_ready
      @failure_sparklines = stats.failure_sparklines
    end
  end
end
