
require_relative "lib/solid_queue_dashboard/version"

Gem::Specification.new do |spec|
  spec.name        = "solid_queue_dashboard"
  spec.version     = SolidQueueDashboard::VERSION
  spec.authors     = [ "Chuck Smith" ]
  spec.email       = [ "eclectic-coding@users.noreply.github.com" ]
  spec.homepage    = "https://github.com/eclectic-coding/solid_queue_dashboard"
  spec.summary     = "A read-only Rails engine dashboard for monitoring Solid Queue jobs."
  spec.description = "Mount SolidQueueDashboard in any Rails app using Solid Queue to get a " \
                     "real-time read-only view of your queues, jobs by status, and failed executions."
  spec.license     = "MIT"

  spec.metadata["homepage_uri"]    = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/eclectic-coding/solid_queue_dashboard"
  spec.metadata["changelog_uri"] = "https://github.com/eclectic-coding/solid_queue_dashboard/blob/main/CHANGELOG.md"

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]
  end

  spec.required_ruby_version = ">= 3.3"

  spec.add_dependency "rails", ">= 8.1.3"
  spec.add_dependency "solid_queue", ">= 1.0"
end
