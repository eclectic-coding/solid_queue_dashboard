SolidQueueWeb::Engine.routes.draw do
  root to: "dashboard#index"

  resources :queues,      only: [ :index ]
  resources :jobs, only: [ :index, :show, :destroy ] do
    collection do
      post :discard_all
    end
  end
  resources :failed_jobs, only: [ :index, :destroy ] do
    collection do
      post :retry_all
      post :discard_all
    end
    member do
      post :retry
    end
  end
end
