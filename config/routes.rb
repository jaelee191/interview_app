Rails.application.routes.draw do
  # Devise routes
  devise_for :users
  
  # User Profiles routes
  resources :user_profiles, only: [:show, :edit, :update] do
    member do
      post 'add_career'
      post 'add_project'
      delete 'remove_career'
      delete 'remove_project'
      post 'update_analysis_preference'
      post 'update_inline'
    end
  end
  
  # Pricing page
  get "pricing", to: "pricing#index"
  
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  root "home#index"
  get "about", to: "home#about"
  
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
      post 'save_to_profile'
      post 'get_ai_suggestion'
      get 'load_profile_data'
      post 'update_profile_from_chat'
      post 'analyze_pdf'
      post 'analyze_text'
      post 'generate_final'
      get 'advanced'
      post 'analyze_advanced'
      get 'deep_analysis'
      post 'perform_deep_analysis'
      get 'job_posting'
      post 'analyze_job_posting'
      get 'job_posting_text'
      post 'analyze_job_text'
      get 'bookmarklet'
      get 'ontology_input'
      get 'ontology_analysis'
      post 'ontology_analysis'
      get 'intelligent_analysis'
      post 'perform_intelligent_analysis'
      get 'integrated_analysis'
      post 'perform_integrated_analysis'
      get 'integrated_analysis_demo'
      get 'saved_job_analyses'
      get 'view_job_analysis/:id', to: 'cover_letters#view_job_analysis', as: 'view_job_analysis'
      post 'save_job_analysis/:id', to: 'cover_letters#save_job_analysis', as: 'save_job_analysis'
      get 'load_job_analysis', to: 'cover_letters#load_job_analysis'
      get 'company_analysis', to: 'cover_letters#company_analysis'
      post 'analyze_company', to: 'cover_letters#analyze_company'
      get 'company_analysis_result/:id', to: 'cover_letters#company_analysis_result', as: 'company_analysis_result'
      post 'save_company_analysis/:id', to: 'cover_letters#save_company_analysis', as: 'save_company_analysis'
      delete 'delete_company_analysis/:id', to: 'cover_letters#delete_company_analysis', as: 'delete_company_analysis'
      get 'saved_company_analyses', to: 'cover_letters#saved_company_analyses'
    end
    member do
      get 'deep_analysis_result'
    end
  end
end