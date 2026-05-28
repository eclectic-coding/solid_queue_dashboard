module SolidQueueWeb
  class AuditController < ApplicationController
    def index
      @action_filter = params[:action_filter].presence_in(AuditEvent::ACTIONS)
      @actor_filter  = params[:actor].presence
      @queue_filter  = params[:queue].presence

      scope = AuditEvent.recent
      scope = scope.where(action:     @action_filter) if @action_filter
      scope = scope.where(actor:      @actor_filter)  if @actor_filter
      scope = scope.where(queue_name: @queue_filter)  if @queue_filter

      respond_to do |format|
        format.html { @pagy, @audit_events = pagy(scope) }
        format.csv do
          send_data audit_csv(scope),
                    filename: "audit-log-#{Date.today}.csv",
                    type: "text/csv", disposition: "attachment"
        end
      end
    end

    private

    def audit_csv(scope)
      CSV.generate(headers: true) do |csv|
        csv << %w[id action actor job_class queue_name item_count created_at]
        scope.each do |event|
          csv << [event.id, event.action, event.actor, event.job_class,
                  event.queue_name, event.item_count, event.created_at.iso8601]
        end
      end
    end
  end
end
