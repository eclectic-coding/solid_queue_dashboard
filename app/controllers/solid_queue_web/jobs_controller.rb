module SolidQueueWeb
  class JobsController < ApplicationController
    def index
      @status    = params[:status].presence_in(Job::STATUSES) || "ready"
      @search    = params[:q].presence
      @period    = params[:period].presence_in(PERIOD_DURATIONS.keys)
      @priority  = params[:priority].presence
      @sort      = params[:sort].presence_in(sortable_columns) || "created_at"
      @direction = params[:direction] == "asc" ? "asc" : "desc"

      scope = Job::EXECUTION_MODELS[@status].includes(:job).references(:job).order(sort_expression)
      scope = scope.where("solid_queue_jobs.class_name LIKE ?", "%#{@search}%")         if @search.present?
      scope = scope.where("solid_queue_jobs.created_at >= ?", PERIOD_DURATIONS[@period].ago) if @period.present?
      scope = scope.where("solid_queue_jobs.priority = ?", @priority.to_i)              if @priority.present?

      @priority_options = Job::EXECUTION_MODELS[@status].joins(:job)
        .distinct.pluck("solid_queue_jobs.priority").sort

      respond_to do |format|
        format.html { @pagy, @jobs = pagy(scope) }
        format.csv do
          send_data jobs_csv(scope),
                    filename: "jobs-#{@status}-#{Date.today}.csv",
                    type: "text/csv", disposition: "attachment"
        end
      end
    end

    def show
      @job = SolidQueue::Job
        .includes(:ready_execution, :scheduled_execution, :claimed_execution, :blocked_execution, :failed_execution)
        .find(params[:id])
      @execution_status = Job.derive_status(@job)
    end

    def destroy
      @status    = params[:status]
      @period    = params[:period].presence_in(PERIOD_DURATIONS.keys)
      @priority  = params[:priority].presence
      @sort      = params[:sort].presence_in(sortable_columns) || "created_at"
      @direction = params[:direction] == "asc" ? "asc" : "desc"
      model = Job.execution_model_for!(@status)
      if params[:id]
        @execution = model.find(params[:id])
        @execution.discard
        @remaining_count = filtered_scope(model).count
        respond_to do |format|
          format.turbo_stream
          format.html { redirect_to jobs_path(status: @status, period: @period, sort: @sort, direction: @direction), notice: "Job discarded." }
        end
      else
        jobs = filtered_scope(model).map(&:job)
        model.discard_all_from_jobs(jobs)
        redirect_to jobs_path(status: @status, period: @period, sort: @sort, direction: @direction),
          notice: "#{jobs.size} #{"job".pluralize(jobs.size)} discarded."
      end
    rescue ArgumentError => e
      redirect_to jobs_path(status: @status, period: @period, sort: @sort, direction: @direction), alert: e.message
    rescue => e
      redirect_to jobs_path(status: @status, period: @period, sort: @sort, direction: @direction),
        alert: "Could not discard #{params[:id] ? "job" : "jobs"}: #{e.message}"
    end

    private

    def sortable_columns
      %w[class_name queue_name priority created_at]
    end

    def sort_expression
      sql_col = case @sort
      when "class_name" then "solid_queue_jobs.class_name"
      when "queue_name" then "solid_queue_jobs.queue_name"
      when "priority"   then "solid_queue_jobs.priority"
      else "#{Job::EXECUTION_MODELS[@status].quoted_table_name}.created_at"
      end
      Arel.sql("#{sql_col} #{@direction == 'asc' ? 'ASC' : 'DESC'}")
    end

    def jobs_csv(scope)
      CSV.generate(headers: true) do |csv|
        csv << %w[id class_name queue_name status priority enqueued_at]
        scope.each do |execution|
          job = execution.job
          csv << [job.id, job.class_name, job.queue_name, @status, job.priority, job.created_at.iso8601]
        end
      end
    end

    def filtered_scope(model)
      scope = model.includes(:job)
      scope = scope.references(:job).where("solid_queue_jobs.created_at >= ?", PERIOD_DURATIONS[@period].ago) if @period.present?
      scope = scope.references(:job).where("solid_queue_jobs.priority = ?", @priority.to_i)                  if @priority.present?
      scope
    end
  end
end
