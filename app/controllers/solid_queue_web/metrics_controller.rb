module SolidQueueWeb
  class MetricsController < ApplicationController
    def index
      render json: MetricsPayload.new.to_h
    end
  end
end
