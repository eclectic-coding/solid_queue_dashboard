require "csv"

module SolidQueueWeb
  class ApplicationController < ActionController::Base
    include Pagy::Method

    PERIOD_DURATIONS   = { "1h" => 1.hour, "24h" => 24.hours, "7d" => 7.days }.freeze
    STAGGER_INTERVALS  = { "5s" => 5.seconds, "10s" => 10.seconds, "30s" => 30.seconds, "1m" => 1.minute }.freeze

    before_action :authenticate!
    around_action :with_database_connection

    private

    def with_database_connection
      config = SolidQueueWeb.connects_to
      return yield unless config

      if replica_configured?(config)
        role = request.get? ? config[:reading] : config[:writing]
        ActiveRecord::Base.connected_to(role: role) { yield }
      else
        ActiveRecord::Base.connected_to(**config) { yield }
      end
    end

    def replica_configured?(config)
      config.key?(:reading) && config.key?(:writing)
    end

    def authenticate!
      return unless (auth = SolidQueueWeb.authenticate)

      instance_exec(&auth) || request_basic_auth
    end

    def request_basic_auth
      request_http_basic_authentication("Solid Queue Dashboard")
    end
  end
end
