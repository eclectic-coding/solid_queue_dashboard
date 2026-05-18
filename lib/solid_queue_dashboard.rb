require "solid_queue_dashboard/version"
require "solid_queue_dashboard/engine"

module SolidQueueDashboard
  class << self
    def authenticate(&block)
      @authenticate = block if block_given?
      @authenticate
    end
  end
end
