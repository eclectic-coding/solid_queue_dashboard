require "pagy"
require "pagy/toolbox/paginators/method"
require "solid_queue"

module SolidQueueDashboard
  class Engine < ::Rails::Engine
    isolate_namespace SolidQueueDashboard
  end
end
