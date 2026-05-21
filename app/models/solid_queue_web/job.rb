module SolidQueueWeb
  class Job
    STATUSES    = %w[ready scheduled claimed blocked failed].freeze
    DISCARDABLE = %w[ready scheduled blocked].freeze
    EXECUTION_MODELS = {
      "ready"     => SolidQueue::ReadyExecution,
      "scheduled" => SolidQueue::ScheduledExecution,
      "claimed"   => SolidQueue::ClaimedExecution,
      "blocked"   => SolidQueue::BlockedExecution,
      "failed"    => SolidQueue::FailedExecution
    }.freeze

    def self.execution_model_for!(status)
      raise ArgumentError, "Cannot discard #{status} jobs from this page." unless DISCARDABLE.include?(status)

      EXECUTION_MODELS[status]
    end

    def self.derive_status(job)
      return "failed"    if job.failed_execution.present?
      return "claimed"   if job.claimed_execution.present?
      return "blocked"   if job.blocked_execution.present?
      return "ready"     if job.ready_execution.present?
      return "scheduled" if job.scheduled_execution.present?

      "finished"
    end
  end
end
