require "solid_queue_web/version"
require "importmap-rails"
require "solid_queue_web/engine"

module SolidQueueWeb
  class << self
    attr_writer :page_size, :dashboard_refresh_interval, :default_refresh_interval, :search_results_limit

    def page_size
      @page_size || 25
    end

    def dashboard_refresh_interval
      @dashboard_refresh_interval || 5_000
    end

    def default_refresh_interval
      @default_refresh_interval || 10_000
    end

    def search_results_limit
      @search_results_limit || 25
    end

    def configure
      yield self
    end

    def authenticate(&block)
      @authenticate = block if block_given?
      @authenticate
    end
  end
end
