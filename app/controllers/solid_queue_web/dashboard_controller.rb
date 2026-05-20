module SolidQueueWeb
  class DashboardController < ApplicationController
    def index
      @stats = DashboardStats.new
    end
  end
end
