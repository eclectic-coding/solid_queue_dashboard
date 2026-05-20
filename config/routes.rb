SolidQueueWeb::Engine.routes.draw do
  root to: "dashboard#index"
  post "retry_all_failed",    to: "dashboard#retry_all_failed",    as: :retry_all_failed
  post "discard_all_blocked", to: "dashboard#discard_all_blocked", as: :discard_all_blocked

  get "search", to: "search#index", as: :search
  get "history", to: "history#index", as: :history

  resources :recurring_tasks, only: [:index]
  resources :processes, only: [:index]
  resources :queues, only: [:index], param: :name do
    member do
      post :pause
      post :resume
    end
    resources :jobs, path: "list", only: [:index, :destroy], controller: "queues/jobs" do
      collection do
        post :discard_all
      end
    end
  end

  # Singular selection resources must be defined before the member routes of their
  # parent resources, otherwise DELETE /list/selection matches /list/:id first.
  resource :job_selection, path: "list/selection", only: [:destroy], controller: "jobs/selections"
  resources :jobs, path: "list", only: [:index, :show, :destroy] do
    collection do
      post :discard_all
    end
  end

  resource :failed_job_selection, path: "failed_jobs/selection", only: [:create, :destroy],
           controller: "failed_jobs/selections"
  resources :failed_jobs, only: [:index, :destroy] do
    collection do
      post :retry_all,   action: :retry
      post :discard_all, action: :destroy
    end
    member do
      post :retry
    end
  end
end
