module SolidQueueWeb
  class FailedJobsController < ApplicationController
    before_action :set_filter_params, only: [:index, :destroy]

    def index
      respond_to do |format|
        format.html { @pagy, @failed_jobs = pagy(filtered_scope.order(sort_expression)) }
        format.csv do
          send_data failed_jobs_csv,
                    filename: "failed-jobs-#{Date.today}.csv",
                    type: "text/csv", disposition: "attachment"
        end
      end
    end

    def destroy
      executions = params[:id] ? [SolidQueue::FailedExecution.find(params[:id])] : filtered_scope.to_a
      perform_discard(executions)
    rescue => e
      redirect_to failed_jobs_path, alert: "Could not discard job: #{e.message}"
    end

    private

    def failed_jobs_csv
      CSV.generate(headers: true) do |csv|
        csv << %w[id class_name queue_name error_class error_message failed_at]
        filtered_scope.order(sort_expression).each do |execution|
          job   = execution.job
          error = execution.error || {}
          csv << [job.id, job.class_name, job.queue_name,
                  error["exception_class"], error["message"],
                  execution.created_at.iso8601]
        end
      end
    end

    def perform_discard(executions)
      jobs = executions.map(&:job)
      action = params[:id] ? "failed_job_discarded" : "failed_jobs_discarded"
      SolidQueue::FailedExecution.discard_all_from_jobs(jobs)
      record_audit(action, job_class: jobs.first&.class_name, queue_name: jobs.first&.queue_name, item_count: jobs.size)
      redirect_to failed_jobs_path(queue: @queue, q: @search, period: @period),
        notice: "#{jobs.size} #{"job".pluralize(jobs.size)} discarded."
    end

    def sortable_columns
      %w[class_name queue_name created_at]
    end

    def sort_expression
      sql_col = case @sort
      when "class_name" then "solid_queue_jobs.class_name"
      when "queue_name" then "solid_queue_jobs.queue_name"
      else "solid_queue_failed_executions.created_at"
      end
      Arel.sql("#{sql_col} #{@direction == 'asc' ? 'ASC' : 'DESC'}")
    end

    def set_filter_params
      @queue     = params[:queue].presence
      @search    = params[:q].presence
      @period    = params[:period].presence_in(PERIOD_DURATIONS.keys)
      @sort      = params[:sort].presence_in(sortable_columns) || "created_at"
      @direction = params[:direction] == "asc" ? "asc" : "desc"
    end

    def filtered_scope
      scope = SolidQueue::FailedExecution.includes(:job)
      scope = scope.references(:job).where(solid_queue_jobs: { queue_name: @queue }) if @queue.present?
      scope = scope.references(:job).where("solid_queue_jobs.class_name LIKE ?", "%#{@search}%") if @search.present?
      scope = scope.references(:job).where("solid_queue_jobs.created_at >= ?", PERIOD_DURATIONS[@period].ago) if @period.present?
      scope
    end
  end
end
