module SolidQueueWeb
  module Queues
    class PausesController < ApplicationController
      def create
        queue = SolidQueue::Queue.find_by_name(params[:queue_name])
        queue.pause
        record_audit("queue_paused", queue_name: queue.name)
        redirect_to queues_path, notice: "Queue \"#{queue.name}\" paused."
      rescue => e
        redirect_to queues_path, alert: "Could not pause queue: #{e.message}"
      end

      def destroy
        queue = SolidQueue::Queue.find_by_name(params[:queue_name])
        queue.resume
        record_audit("queue_resumed", queue_name: queue.name)
        redirect_to queues_path, notice: "Queue \"#{queue.name}\" resumed."
      rescue => e
        redirect_to queues_path, alert: "Could not resume queue: #{e.message}"
      end
    end
  end
end
