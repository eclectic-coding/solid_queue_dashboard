module SolidQueueWeb
  class QueuesController < ApplicationController
    def index
      @queues = SolidQueue::Queue.all.sort_by(&:name)
    end

    def pause
      queue = SolidQueue::Queue.find_by_name(params[:name])
      queue.pause
      redirect_to queues_path, notice: "Queue \"#{queue.name}\" paused."
    rescue => e
      redirect_to queues_path, alert: "Could not pause queue: #{e.message}"
    end

    def resume
      queue = SolidQueue::Queue.find_by_name(params[:name])
      queue.resume
      redirect_to queues_path, notice: "Queue \"#{queue.name}\" resumed."
    rescue => e
      redirect_to queues_path, alert: "Could not resume queue: #{e.message}"
    end
  end
end
