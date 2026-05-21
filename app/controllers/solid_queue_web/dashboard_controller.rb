module SolidQueueWeb
  class DashboardController < ApplicationController
    def index
      @stats = DashboardStats.new
      AlertWebhook.call(failure_count: @stats.counts[:failed])
    end
  end
end
