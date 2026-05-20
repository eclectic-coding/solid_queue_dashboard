SolidQueueWeb::Engine.routes.draw do
  root to: "dashboard#index"
  resource :blocked_jobs, only: [:destroy]

  get "search", to: "search#index", as: :search
  get "history", to: "history#index", as: :history

  resources :recurring_tasks, only: [:index]
  resources :processes, only: [:index]
  resources :queues, only: [:index], param: :name do
    resource :pause, only: [:create, :destroy], controller: "queues/pauses"
    resources :jobs, path: "list", only: [:index, :destroy], controller: "queues/jobs" do
      collection do
        post :discard_all, action: :destroy
      end
    end
  end

  # Singular selection resources must be defined before the member routes of their
  # parent resources, otherwise DELETE /list/selection matches /list/:id first.
  resource :job_selection, path: "list/selection", only: [:destroy], controller: "jobs/selections"
  resources :jobs, path: "list", only: [:index, :show, :destroy] do
    collection do
      post :discard_all, action: :destroy
    end
  end

  resource :failed_job_selection, path: "failed_jobs/selection", only: [:create, :destroy],
           controller: "failed_jobs/selections"
  resources :failed_jobs, only: [:index, :destroy] do
    collection do
      post :retry_all,   to: "retry_failed_jobs#create"
      post :discard_all, action: :destroy
    end
    member do
      post :retry, to: "retry_failed_jobs#create"
    end
  end
end
