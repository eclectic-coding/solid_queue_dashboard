module SolidQueueDashboard
  class QueuesController < ApplicationController
    def index
      all_queues = SolidQueue::Queue.all.sort_by(&:name)
      @pagy, @queues = pagy_array(all_queues, limit: 50)
    end

    def pause
      queue = SolidQueue::Queue.find_by_name(params[:id])
      queue.pause
      redirect_to queues_path, notice: "Queue \"#{queue.name}\" paused."
    end

    def resume
      queue = SolidQueue::Queue.find_by_name(params[:id])
      queue.resume
      redirect_to queues_path, notice: "Queue \"#{queue.name}\" resumed."
    end
  end
end
