module SolidQueueWeb
  class PerformanceController < ApplicationController
    def index
      @period = params[:period].presence_in(PERIOD_DURATIONS.keys)

      scope = SolidQueue::Job.where.not(finished_at: nil)
      scope = scope.where("finished_at >= ?", PERIOD_DURATIONS[@period].ago) if @period.present?

      @rows = JobPerformanceStats.new(scope).rows
    end
  end
end
