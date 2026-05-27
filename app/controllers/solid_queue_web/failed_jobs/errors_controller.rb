module SolidQueueWeb
  module FailedJobs
    class ErrorsController < ApplicationController
      def index
        @groups = ErrorFrequencyReport.new.groups
      end
    end
  end
end
