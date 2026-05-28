module SolidQueueWeb
  class DashboardController < ApplicationController
    def index
      @stats = DashboardStats.new
      AlertWebhook.call(failure_count: @stats.counts[:failed])
      QueueDepthAlert.call
      SlowJobAlert.call
      StaleProcessAlert.call
    end
  end
end
