Rails.application.routes.draw do
  mount SolidQueueWeb::Engine, at: "/jobs"
end
