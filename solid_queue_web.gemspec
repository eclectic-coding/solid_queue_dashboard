
require_relative "lib/solid_queue_web/version"

Gem::Specification.new do |spec|
  spec.name        = "solid_queue_web"
  spec.version     = SolidQueueWeb::VERSION
  spec.authors     = ["Chuck Smith"]
  spec.email       = ["eclectic-coding@users.noreply.github.com"]
  spec.homepage    = "https://github.com/eclectic-coding/solid_queue_web"
  spec.summary     = "A Rails engine dashboard for monitoring and managing Solid Queue jobs."
  spec.description = "Mount SolidQueueWeb in any Rails app using Solid Queue to get a full-featured " \
                     "job dashboard: inspect jobs by status (ready, scheduled, running, blocked, failed), " \
                     "retry or discard failed jobs, reschedule or run scheduled jobs immediately, " \
                     "manage recurring tasks, filter by queue/priority/period, export to CSV, " \
                     "detect slow jobs, view queue depth sparklines, track job performance (p50/p95), " \
                     "and scrape a /metrics JSON endpoint for external monitoring — all without leaving your app."
  spec.license     = "MIT"

  spec.metadata["homepage_uri"]    = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/eclectic-coding/solid_queue_web"
  spec.metadata["changelog_uri"] = "https://github.com/eclectic-coding/solid_queue_web/blob/main/CHANGELOG.md"

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]
  end

  spec.required_ruby_version = ">= 3.3"

  spec.add_dependency "rails", ">= 8.1.3"
  spec.add_dependency "csv", ">= 3.0"
  spec.add_dependency "solid_queue", ">= 1.0"
  spec.add_dependency "pagy", ">= 43.0"
  spec.add_dependency "turbo-rails", ">= 2.0"
  spec.add_dependency "importmap-rails", ">= 1.2"
end
