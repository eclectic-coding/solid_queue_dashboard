
require_relative "lib/solid_queue_web/version"

Gem::Specification.new do |spec|
  spec.name        = "solid_queue_web"
  spec.version     = SolidQueueWeb::VERSION
  spec.authors     = [ "Chuck Smith" ]
  spec.email       = [ "eclectic-coding@users.noreply.github.com" ]
  spec.homepage    = "https://github.com/eclectic-coding/solid_queue_web"
  spec.summary     = "A Rails engine dashboard for monitoring and managing Solid Queue jobs."
  spec.description = "Mount SolidQueueWeb in any Rails app using Solid Queue to get a " \
                     "dashboard for your queues, jobs by status, failed executions, and job actions " \
                     "(retry, discard) — all without leaving your app."
  spec.license     = "MIT"

  spec.metadata["homepage_uri"]    = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/eclectic-coding/solid_queue_web"
  spec.metadata["changelog_uri"] = "https://github.com/eclectic-coding/solid_queue_web/blob/main/CHANGELOG.md"

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]
  end

  spec.required_ruby_version = ">= 3.3"

  spec.add_dependency "rails", ">= 8.1.3"
  spec.add_dependency "solid_queue", ">= 1.0"
  spec.add_dependency "pagy", ">= 43.0"
  spec.add_dependency "turbo-rails", ">= 2.0"
end
