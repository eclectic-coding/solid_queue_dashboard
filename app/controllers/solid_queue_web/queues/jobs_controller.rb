module SolidQueueWeb
  module Queues
    class JobsController < ApplicationController
      before_action :set_queue
      before_action :set_status, only: [ :destroy, :discard_all ]

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
        @execution = model.find(params[:id])
        @execution.discard
        @remaining_count = filtered_scope(model).count
        respond_to do |format|
          format.turbo_stream
          format.html { redirect_to queue_jobs_path(queue_name: @queue, status: @status), notice: "Job discarded." }
        end
      rescue ArgumentError => e
        redirect_to queue_jobs_path(queue_name: @queue, status: @status), alert: e.message
      rescue => e
        redirect_to queue_jobs_path(queue_name: @queue, status: @status), alert: "Could not discard job: #{e.message}"
      end

      def discard_all
        model = execution_model_for!(@status)
        jobs = filtered_scope(model).map(&:job)
        model.discard_all_from_jobs(jobs)
        redirect_to queue_jobs_path(queue_name: @queue, status: @status),
          notice: "#{jobs.size} #{"job".pluralize(jobs.size)} discarded."
      rescue ArgumentError => e
        redirect_to queue_jobs_path(queue_name: @queue, status: @status), alert: e.message
      rescue => e
        redirect_to queue_jobs_path(queue_name: @queue, status: @status), alert: "Could not discard jobs: #{e.message}"
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
        raise ArgumentError, "Cannot discard #{status} jobs from this page." unless Job::DISCARDABLE.include?(status)
        Job::EXECUTION_MODELS[status]
      end
    end
  end
end
