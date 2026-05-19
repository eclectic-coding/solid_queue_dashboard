module SolidQueueWeb
  class ApplicationController < ActionController::Base
    include Pagy::Method

    PERIOD_DURATIONS = { "1h" => 1.hour, "24h" => 24.hours, "7d" => 7.days }.freeze

    before_action :authenticate!

    private

    def authenticate!
      return unless (auth = SolidQueueWeb.authenticate)

      instance_exec(&auth) || request_basic_auth
    end

    def request_basic_auth
      request_http_basic_authentication("Solid Queue Dashboard")
    end
  end
end
