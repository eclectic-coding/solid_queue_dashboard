require "solid_queue"

module SolidQueueWeb
  class Engine < ::Rails::Engine
    isolate_namespace SolidQueueWeb
  end
end
