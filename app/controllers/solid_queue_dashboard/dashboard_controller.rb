module SolidQueueDashboard
  class DashboardController < ApplicationController
    def index
      @stats = {
        ready:    SolidQueue::ReadyExecution.count,
        scheduled: SolidQueue::ScheduledExecution.count,
        claimed:  SolidQueue::ClaimedExecution.count,
        failed:   SolidQueue::FailedExecution.count,
        blocked:  SolidQueue::BlockedExecution.count,
        queues:   SolidQueue::Queue.count,
        processes: SolidQueue::Process.count
      }
    end
  end
end