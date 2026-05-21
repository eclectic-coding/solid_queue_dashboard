job_classes = %w[
  UserMailerJob
  ReportGeneratorJob
  DataSyncJob
  ImageProcessingJob
  NotificationJob
  InvoiceGeneratorJob
  CleanupJob
  ExportJob
]

queues = %w[default mailers critical low_priority]

puts "Clearing existing data..."
conn = ActiveRecord::Base.connection
%w[
  solid_queue_failed_executions
  solid_queue_scheduled_executions
  solid_queue_claimed_executions
  solid_queue_blocked_executions
  solid_queue_ready_executions
  solid_queue_recurring_executions
  solid_queue_recurring_tasks
  solid_queue_jobs
  solid_queue_processes
  solid_queue_semaphores
].each { |t| conn.execute("DELETE FROM #{t}") }
conn.execute("DELETE FROM sqlite_sequence WHERE name LIKE 'solid_queue%'") rescue nil

puts "Seeding processes..."
supervisor = SolidQueue::Process.create!(kind: "Supervisor", pid: 12_345, hostname: "web-1.local", name: "supervisor-web-1",  last_heartbeat_at: 10.seconds.ago,  metadata: { queues: queues }.to_json)
worker0    = SolidQueue::Process.create!(kind: "Worker",     pid: 12_346, hostname: "web-1.local", name: "worker-0-web-1",   last_heartbeat_at: 5.seconds.ago,   metadata: { queues: %w[default mailers], thread_count: 3 }.to_json)
worker1    = SolidQueue::Process.create!(kind: "Worker",     pid: 12_347, hostname: "web-1.local", name: "worker-1-web-1",   last_heartbeat_at: 8.seconds.ago,   metadata: { queues: %w[critical], thread_count: 1 }.to_json)
SolidQueue::Process.create!(kind: "Dispatcher", pid: 12_348, hostname: "web-1.local", name: "dispatcher-web-1", last_heartbeat_at: 12.seconds.ago, metadata: { polling_interval: 1 }.to_json, supervisor_id: supervisor.id)
workers = [worker0, worker1]

puts "Seeding ready jobs..."
# Job.create! triggers after_create :prepare_for_execution which auto-creates ReadyExecution
12.times do |i|
  SolidQueue::Job.create!(
    queue_name: queues.sample,
    class_name: job_classes.sample,
    arguments: { job_id: i + 1, user_id: rand(1000) }.to_json,
    priority: [0, 5, 10].sample,
    active_job_id: SecureRandom.uuid,
    created_at: rand(1..48).hours.ago,
    updated_at: rand(1..48).hours.ago
  )
end

puts "Seeding scheduled jobs..."
# Jobs with a future scheduled_at trigger schedule instead of dispatch, auto-creating ScheduledExecution
8.times do |i|
  SolidQueue::Job.create!(
    queue_name: queues.sample,
    class_name: job_classes.sample,
    arguments: { report_id: i + 1 }.to_json,
    priority: 0,
    active_job_id: SecureRandom.uuid,
    scheduled_at: rand(1..72).hours.from_now,
    created_at: rand(1..24).hours.ago,
    updated_at: rand(1..24).hours.ago
  )
end

puts "Seeding claimed (running) jobs..."
# Create ready jobs then move them to claimed
3.times do |i|
  job = SolidQueue::Job.create!(
    queue_name: queues.sample,
    class_name: job_classes.sample,
    arguments: { batch: i + 1 }.to_json,
    priority: 0,
    active_job_id: SecureRandom.uuid,
    created_at: rand(1..4).minutes.ago,
    updated_at: rand(1..4).minutes.ago
  )
  job.ready_execution&.destroy
  SolidQueue::ClaimedExecution.create!(job: job, process: workers.sample, created_at: job.created_at)
end

puts "Seeding slow claimed jobs (for slow job detection)..."
# These exceed a 5-minute threshold — visible as orange rows when slow_job_threshold is configured
slow_durations = [8.minutes, 20.minutes, 45.minutes]
slow_durations.each_with_index do |duration, i|
  job = SolidQueue::Job.create!(
    queue_name: queues.sample,
    class_name: job_classes.sample,
    arguments: { slow_job: true, idx: i }.to_json,
    priority: 0,
    active_job_id: SecureRandom.uuid,
    created_at: duration.ago,
    updated_at: duration.ago
  )
  job.ready_execution&.destroy
  SolidQueue::ClaimedExecution.create!(job: job, process: workers.sample, created_at: duration.ago)
end

puts "Seeding failed jobs..."
errors = [
  { class: "RuntimeError",                    message: "undefined method `foo' for nil:NilClass" },
  { class: "ActiveRecord::RecordNotFound",    message: "Couldn't find User with 'id'=42" },
  { class: "Net::ReadTimeout",                message: "Net::ReadTimeout with #<TCPSocket:(closed)>" },
  { class: "ArgumentError",                   message: "wrong number of arguments (given 2, expected 1)" },
  { class: "StandardError",                   message: "S3 bucket not found: my-app-uploads" }
]

6.times do |i|
  err = errors[i % errors.size]
  job = SolidQueue::Job.create!(
    queue_name: queues.sample,
    class_name: job_classes.sample,
    arguments: { attempt: i + 1 }.to_json,
    priority: 0,
    active_job_id: SecureRandom.uuid,
    created_at: rand(1..72).hours.ago,
    updated_at: rand(1..72).hours.ago
  )
  job.ready_execution&.destroy
  SolidQueue::FailedExecution.create!(
    job: job,
    error: { exception_class: err[:class], message: err[:message], backtrace: ["app/jobs/#{job.class_name.underscore}.rb:42"] },
    created_at: job.created_at
  )
end

puts "Seeding recent failed jobs (for failure rate sparkline)..."
3.times do |i|
  err = errors[i % errors.size]
  job = SolidQueue::Job.create!(
    queue_name: queues.sample,
    class_name: job_classes.sample,
    arguments: { recent_fail: true, idx: i }.to_json,
    priority: 0,
    active_job_id: SecureRandom.uuid,
    created_at: rand(1..10).hours.ago,
    updated_at: rand(1..10).hours.ago
  )
  job.ready_execution&.destroy
  SolidQueue::FailedExecution.create!(
    job: job,
    error: { exception_class: err[:class], message: err[:message], backtrace: ["app/jobs/#{job.class_name.underscore}.rb:42"] },
    created_at: job.created_at
  )
end

puts "Seeding blocked jobs..."
# Skip set_expires_at callback which requires a real ActiveJob class to exist
SolidQueue::BlockedExecution.skip_callback(:create, :before, :set_expires_at)
begin
  5.times do |i|
    job = SolidQueue::Job.create!(
      queue_name: queues.sample,
      class_name: job_classes.sample,
      arguments: { item_id: i + 1 }.to_json,
      priority: 0,
      active_job_id: SecureRandom.uuid,
      concurrency_key: "#{job_classes.sample}/#{i + 1}",
      created_at: rand(1..12).hours.ago,
      updated_at: rand(1..12).hours.ago
    )
    job.ready_execution&.destroy
    SolidQueue::BlockedExecution.create!(
      job: job,
      queue_name: job.queue_name,
      priority: job.priority,
      expires_at: rand(1..4).hours.from_now,
      created_at: job.created_at
    )
  end
ensure
  SolidQueue::BlockedExecution.set_callback(:create, :before, :set_expires_at)
end

puts "Seeding finished jobs (for throughput chart)..."
# Recent jobs — guaranteed within last 30 minutes so Done (1h) is non-zero
5.times do |i|
  job = SolidQueue::Job.new(
    queue_name: queues.sample,
    class_name: job_classes.sample,
    arguments: { recent: true, idx: i }.to_json,
    priority: 0,
    active_job_id: SecureRandom.uuid
  )
  finished_at = rand(2..28).minutes.ago
  job.finished_at = finished_at
  job.created_at  = finished_at - rand(10..60).seconds
  job.updated_at  = finished_at
  job.save!(validate: false)
end

# Distributed across last 24h with a realistic daily pattern (more during business hours)
hour_weights = [0, 0, 1, 1, 1, 1, 2, 3, 5, 6, 6, 5, 4, 5, 6, 6, 5, 4, 3, 3, 2, 2, 1, 1]
hour_weights.each_with_index do |weight, hours_ago|
  next if hours_ago == 0
  weight.times do |i|
    job = SolidQueue::Job.new(
      queue_name: queues.sample,
      class_name: job_classes.sample,
      arguments: { finished_seed: true, idx: i }.to_json,
      priority: 0,
      active_job_id: SecureRandom.uuid
    )
    finished_at = (hours_ago + rand).hours.ago
    job.finished_at = finished_at
    job.created_at  = finished_at - rand(10..120).seconds
    job.updated_at  = finished_at
    job.save!(validate: false)
  end
end

puts "Seeding recurring tasks..."
recurring_tasks_data = [
  { key: "nightly-cleanup",      schedule: "0 2 * * *",    command: "CleanupJob.perform_later",               queue_name: "default",      description: "Nightly database cleanup",                          static: true  },
  { key: "hourly-data-sync",     schedule: "0 * * * *",    command: "DataSyncJob.perform_later",              queue_name: "default",      description: "Sync data from external APIs every hour",           static: true  },
  { key: "weekly-report",        schedule: "0 8 * * 1",    command: "ReportGeneratorJob.perform_later",       queue_name: "low_priority", description: "Generate weekly summary report on Monday morning",  static: true  },
  { key: "send-digest-email",    schedule: "0 9 * * *",    command: "UserMailerJob.perform_later",            queue_name: "mailers",      description: "Daily digest email to all users",                   static: true  },
  { key: "export-invoices",      schedule: "30 1 1 * *",   command: "InvoiceGeneratorJob.perform_later",      queue_name: "critical",     description: "Monthly invoice export on the 1st",                 static: true  },
  { key: "purge-old-images",     schedule: "0 3 * * 0",    command: "ImageProcessingJob.perform_later",       queue_name: "low_priority", description: "Weekly purge of unattached image uploads",          static: true  },
  { key: "dynamic-notification", schedule: "*/15 * * * *", command: "NotificationJob.perform_later",          queue_name: "mailers",      description: "Push notifications every 15 minutes",               static: false }
]

recurring_tasks_data.each { |attrs| SolidQueue::RecurringTask.create!(attrs) }

puts "Done! Created:"
puts "  #{SolidQueue::ReadyExecution.count} ready jobs"
puts "  #{SolidQueue::ScheduledExecution.count} scheduled jobs"
puts "  #{SolidQueue::ClaimedExecution.count} claimed (running) jobs"
puts "  #{SolidQueue::BlockedExecution.count} blocked jobs"
puts "  #{SolidQueue::FailedExecution.count} failed jobs"
puts "  #{SolidQueue::Process.count} processes"
puts "  #{SolidQueue::Job.where.not(finished_at: nil).count} finished jobs"
puts "  #{SolidQueue::RecurringTask.count} recurring tasks"
