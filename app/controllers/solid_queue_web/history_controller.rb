module SolidQueueWeb
  class HistoryController < ApplicationController
    def index
      @queue  = params[:queue].presence
      @search = params[:q].presence
      @period = params[:period].presence_in(PERIOD_DURATIONS.keys)

      scope = SolidQueue::Job.where.not(finished_at: nil)
      scope = scope.where(queue_name: @queue)                                    if @queue.present?
      scope = scope.where("class_name LIKE ?", "%#{@search}%")                  if @search.present?
      scope = scope.where("finished_at >= ?", PERIOD_DURATIONS[@period].ago)    if @period.present?

      @pagy, @jobs = pagy(scope.order(finished_at: :desc))
    end
  end
end
