module SolidQueueDashboard
  class QueuesController < ApplicationController
    def index
      @queues = SolidQueue::Queue.all.sort_by(&:name)
    end
  end
end
