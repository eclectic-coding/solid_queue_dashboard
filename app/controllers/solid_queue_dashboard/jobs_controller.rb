module SolidQueueDashboard
  class JobsController < ApplicationController
    STATUSES = %w[ready scheduled claimed blocked failed].freeze

    def index
      @status = params[:status].presence_in(STATUSES) || "ready"
      @queue  = params[:queue].presence

      @jobs = case @status
      when "ready"     then SolidQueue::ReadyExecution.includes(:job)
      when "scheduled" then SolidQueue::ScheduledExecution.includes(:job)
      when "claimed"   then SolidQueue::ClaimedExecution.includes(:job)
      when "blocked"   then SolidQueue::BlockedExecution.includes(:job)
      when "failed"    then SolidQueue::FailedExecution.includes(:job)
      end

      @jobs = @jobs.where(jobs: { queue_name: @queue }) if @queue.present?
      @jobs = @jobs.order(created_at: :desc).limit(100)
    end
  end
end
