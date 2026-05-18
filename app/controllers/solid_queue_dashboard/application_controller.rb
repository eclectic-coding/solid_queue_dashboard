module SolidQueueDashboard
  class ApplicationController < ActionController::Base
    before_action :authenticate!

    private

    def authenticate!
      return unless (auth = SolidQueueDashboard.authenticate)

      instance_exec(&auth) || request_basic_auth
    end

    def request_basic_auth
      request_http_basic_authentication("Solid Queue Dashboard")
    end
  end
end
