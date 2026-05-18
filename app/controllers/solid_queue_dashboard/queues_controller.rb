module SolidQueueDashboard
  class QueuesController < ApplicationController
    def index
      @queues = SolidQueue::Queue.order(:name)
    end

    def pause
      queue = SolidQueue::Queue.find_by!(name: params[:id])
      queue.pause
      redirect_to queues_path, notice: "Queue \"#{queue.name}\" paused."
    end

    def resume
      queue = SolidQueue::Queue.find_by!(name: params[:id])
      queue.resume
      redirect_to queues_path, notice: "Queue \"#{queue.name}\" resumed."
    end
  end
end