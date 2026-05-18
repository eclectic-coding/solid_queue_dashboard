SolidQueueDashboard::Engine.routes.draw do
  root to: "dashboard#index"

  resources :queues, only: [ :index ] do
    member do
      post :pause
      post :resume
    end
  end

  resources :jobs, only: [ :index ]

  resources :failed_jobs, only: [ :index ] do
    member do
      post :retry
      delete :discard
    end
    collection do
      delete :discard_all
    end
  end
end
