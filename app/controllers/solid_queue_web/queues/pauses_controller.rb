module SolidQueueWeb
  module Queues
    class PausesController < ApplicationController
      def create
        queue = SolidQueue::Queue.find_by_name(params[:queue_name])
        queue.pause
        record_audit("queue_paused", queue_name: queue.name)
        redirect_to queues_path, notice: t("solid_queue_web.flash.queue_paused", name: queue.name)
      rescue => e
        redirect_to queues_path, alert: t("solid_queue_web.flash.cannot_pause_queue", error: e.message)
      end

      def destroy
        queue = SolidQueue::Queue.find_by_name(params[:queue_name])
        queue.resume
        record_audit("queue_resumed", queue_name: queue.name)
        redirect_to queues_path, notice: t("solid_queue_web.flash.queue_resumed", name: queue.name)
      rescue => e
        redirect_to queues_path, alert: t("solid_queue_web.flash.cannot_resume_queue", error: e.message)
      end
    end
  end
end
