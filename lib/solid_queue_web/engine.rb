require "solid_queue"
require "pagy"
require "pagy/toolbox/paginators/method"
require "turbo-rails"

module SolidQueueWeb
  class Engine < ::Rails::Engine
    isolate_namespace SolidQueueWeb

    config.i18n.load_path += Gem.find_files("pagy/locales/en.yml")

    initializer "solid_queue_web.pagy" do
      Pagy::OPTIONS[:limit] = 25
    end
  end
end
