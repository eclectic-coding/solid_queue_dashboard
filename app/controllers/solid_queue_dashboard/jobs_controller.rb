module SolidQueueDashboard
  class JobsController < ApplicationController
    STATUSES = %w[ready scheduled claimed blocked failed].freeze

    def index
      @status = params[:status].presence_in(STATUSES) || "ready"
      @queue  = params[:queue].presence

      scope = case @status
      when "ready"     then SolidQueue::ReadyExecution.includes(:job)
      when "scheduled" then SolidQueue::ScheduledExecution.includes(:job)
      when "claimed"   then SolidQueue::ClaimedExecution.includes(:job)
      when "blocked"   then SolidQueue::BlockedExecution.includes(:job)
      when "failed"    then SolidQueue::FailedExecution.includes(:job)
      end

      scope = scope.where(jobs: { queue_name: @queue }) if @queue.present?
      scope = scope.order(created_at: :desc)

      @pagy, @jobs = pagy(scope, limit: 50)
    end
  end
end
