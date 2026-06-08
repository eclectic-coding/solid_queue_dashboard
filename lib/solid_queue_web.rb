require "solid_queue_web/version"
require "importmap-rails"
require "solid_queue_web/engine"

module SolidQueueWeb
  class << self
    attr_writer :page_size, :dashboard_refresh_interval, :default_refresh_interval, :search_results_limit,
                :slow_job_threshold, :alert_webhook_url, :alert_failure_threshold, :alert_webhook_cooldown,
                :alert_queue_thresholds, :alert_slow_job_count_threshold, :alert_stale_process_threshold,
                :connects_to, :time_zone, :available_locales

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

    def slow_job_threshold
      @slow_job_threshold
    end

    def alert_webhook_url
      @alert_webhook_url
    end

    def alert_failure_threshold
      @alert_failure_threshold
    end

    def alert_webhook_cooldown
      @alert_webhook_cooldown || 3600
    end

    def alert_queue_thresholds
      @alert_queue_thresholds || {}
    end

    def alert_slow_job_count_threshold
      @alert_slow_job_count_threshold
    end

    def alert_stale_process_threshold
      @alert_stale_process_threshold
    end

    def connects_to
      @connects_to
    end

    def time_zone
      @time_zone
    end

    def available_locales
      @available_locales || %i[en]
    end

    def configure
      yield self
    end

    def authenticate(&block)
      @authenticate = block if block_given?
      @authenticate
    end

    def current_actor(&block)
      @current_actor = block if block_given?
      @current_actor
    end
  end
end
