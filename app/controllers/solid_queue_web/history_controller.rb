module SolidQueueWeb
  class HistoryController < ApplicationController
    def index
      @queue  = params[:queue].presence
      @search = params[:q].presence
      @period = params[:period].presence_in(PERIOD_DURATIONS.keys)

      scope = SolidQueue::Job.where.not(finished_at: nil)
      scope = scope.where(queue_name: @queue)                                    if @queue.present?
      scope = scope.where("class_name LIKE ?", "%#{@search}%")                  if @search.present?
      scope = scope.where("finished_at >= ?", PERIOD_DURATIONS[@period].ago)    if @period.present?

      respond_to do |format|
        format.html { @pagy, @jobs = pagy(scope.order(finished_at: :desc)) }
        format.csv do
          send_data history_csv(scope),
                    filename: "job-history-#{Date.today}.csv",
                    type: "text/csv", disposition: "attachment"
        end
      end
    end

    private

    def history_csv(scope)
      CSV.generate(headers: true) do |csv|
        csv << %w[id class_name queue_name duration_seconds finished_at]
        scope.order(finished_at: :desc).each do |job|
          duration = job.finished_at && job.created_at ? (job.finished_at - job.created_at).round : nil
          csv << [job.id, job.class_name, job.queue_name, duration, job.finished_at.iso8601]
        end
      end
    end
  end
end
