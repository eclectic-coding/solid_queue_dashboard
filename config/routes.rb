SolidQueueDashboard::Engine.routes.draw do
  root to: "dashboard#index"

  resources :queues,      only: [ :index ]
  resources :jobs,        only: [ :index ]
  resources :failed_jobs, only: [ :index ]
end
