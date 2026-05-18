require_relative "boot"

require "rails/all"

Bundler.require(*Rails.groups)

module Dummy
  class Application < Rails::Application
    config.root = File.expand_path("..", __dir__)
    config.load_defaults 8.1
    config.eager_load = false
    config.active_support.deprecation = :stderr
  end
end
