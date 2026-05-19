module SolidQueueWeb
  class Job
    STATUSES = %w[ready scheduled claimed blocked failed].freeze
    DISCARDABLE = %w[ready scheduled blocked].freeze
    EXECUTION_MODELS = {
      "ready"     => SolidQueue::ReadyExecution,
      "scheduled" => SolidQueue::ScheduledExecution,
      "claimed"   => SolidQueue::ClaimedExecution,
      "blocked"   => SolidQueue::BlockedExecution,
      "failed"    => SolidQueue::FailedExecution
    }.freeze
  end
end