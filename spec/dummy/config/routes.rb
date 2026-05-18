Rails.application.routes.draw do
  mount SolidQueueDashboard::Engine, at: "/jobs"
end
