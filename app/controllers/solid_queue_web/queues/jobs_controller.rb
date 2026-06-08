module SolidQueueWeb
  module Queues
    class JobsController < ApplicationController
      before_action :set_queue
      before_action :set_status, only: [:destroy]

      def index
        @status = params[:status].presence_in(Job::STATUSES) || "ready"
        @search = params[:q].presence
        @jobs   = Job::EXECUTION_MODELS[@status].includes(:job)
                    .where(solid_queue_jobs: { queue_name: @queue })
        @jobs   = @jobs.references(:job).where("solid_queue_jobs.class_name LIKE ?", "%#{@search}%") if @search.present?
        @pagy, @jobs = pagy(@jobs.order(created_at: :desc))
      end

      def destroy
        model = execution_model_for!(@status)
        if params[:id]
          @execution = model.find(params[:id])
          @execution.discard
          @remaining_count = filtered_scope(model).count
          respond_to do |format|
            format.turbo_stream
            format.html { redirect_to queue_jobs_path(queue_name: @queue, status: @status), notice: t("solid_queue_web.flash.job_discarded") }
          end
        else
          jobs = filtered_scope(model).map(&:job)
          model.discard_all_from_jobs(jobs)
          redirect_to queue_jobs_path(queue_name: @queue, status: @status),
            notice: t("solid_queue_web.flash.jobs_discarded", count: jobs.size)
        end
      rescue ArgumentError => e
        redirect_to queue_jobs_path(queue_name: @queue, status: @status), alert: e.message
      rescue => e
        msg = params[:id] ? t("solid_queue_web.flash.cannot_discard_job", error: e.message) : t("solid_queue_web.flash.cannot_discard_jobs", error: e.message)
        redirect_to queue_jobs_path(queue_name: @queue, status: @status), alert: msg
      end

      private

      def set_queue
        @queue = params[:queue_name]
      end

      def set_status
        @status = params[:status]
      end

      def filtered_scope(model)
        model.includes(:job).where(solid_queue_jobs: { queue_name: @queue })
      end

      def execution_model_for!(status)
        raise ArgumentError, t("solid_queue_web.flash.cannot_discard_from_queue", status: status) unless Job::DISCARDABLE.include?(status)
        Job::EXECUTION_MODELS[status]
      end
    end
  end
end
