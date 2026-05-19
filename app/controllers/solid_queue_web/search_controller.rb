module SolidQueueWeb
  class SearchController < ApplicationController
    LIMIT = 25

    def index
      @query      = params[:q].presence
      @job_classes = SolidQueue::Job.distinct.order(:class_name).pluck(:class_name)
      @results    = {}

      return unless @query

      Job::EXECUTION_MODELS.each do |status, model|
        scope = model.includes(:job)
                     .references(:job)
                     .where("solid_queue_jobs.class_name LIKE ?", "%#{@query}%")
                     .order(created_at: :desc)
        total      = scope.count
        executions = scope.limit(LIMIT).to_a
        @results[status] = { executions: executions, total: total } unless executions.empty?
      end
    end
  end
end
