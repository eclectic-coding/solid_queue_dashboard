require "solid_queue_web/version"
require "solid_queue_web/engine"

module SolidQueueWeb
  class << self
    def authenticate(&block)
      @authenticate = block if block_given?
      @authenticate
    end
  end
end
