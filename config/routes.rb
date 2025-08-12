Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  root "home#index"
  
  # Companies routes
  resources :companies do
    member do
      post 'crawl'
    end
    collection do
      get 'search'
    end
  end
  
  # Articles routes for news crawling
  resources :articles, only: [:index, :show]
  
  # Cover Letters routes for AI analysis
  resources :cover_letters, only: [:index, :new, :create, :show, :destroy] do
    collection do
      get 'interactive'
      post 'start_interactive'
      post 'send_message'
      post 'save_interactive'
      get 'advanced'
      post 'analyze_advanced'
      get 'job_posting'
      post 'analyze_job_posting'
      get 'job_posting_text'
      post 'analyze_job_text'
      get 'bookmarklet'
    end
  end
end
