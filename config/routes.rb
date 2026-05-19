SolidQueueWeb::Engine.routes.draw do
  root to: "dashboard#index"

  get "search", to: "search#index", as: :search

  resources :recurring_tasks, only: [ :index ]
  resources :processes, only: [ :index ]
  resources :queues, only: [ :index ], param: :name do
    member do
      post :pause
      post :resume
    end
    resources :jobs, path: "list", only: [ :index, :destroy ], controller: "queues/jobs" do
      collection do
        post :discard_all
      end
    end
  end
  resources :jobs, path: "list", only: [ :index, :show, :destroy ] do
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
