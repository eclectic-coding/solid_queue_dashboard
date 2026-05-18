module SolidQueueWeb
  class ProcessesController < ApplicationController
    def index
      @processes = SolidQueue::Process.order(:kind, :name).to_a
    end
  end
end
