Rails.application.routes.draw do
  # Devise routes
  devise_for :users

  # User Profiles routes
  resources :user_profiles, only: [ :show, :edit, :update ] do
    member do
      post "add_career"
      post "add_project"
      delete "remove_career"
      delete "remove_project"
      post "update_analysis_preference"
      post "update_inline"
    end
  end

  # Mypage routes
  get "mypage", to: "mypage#index"
  get "mypage/cover_letters", to: "mypage#cover_letters"
  get "mypage/job_analyses", to: "mypage#job_analyses"
  get "mypage/company_analyses", to: "mypage#company_analyses"

  # Pricing page
  get "pricing", to: "pricing#index"
  get "pricing/upgrade", to: "pricing#upgrade"
  get "referral", to: "referral#landing"
  post "referral/reviews", to: "referral#create_review"
  get "r/:code", to: "referrals#show", as: :referral_redirect
  post "pricing/purchase_pack", to: "pricing#purchase_pack"
  post "pricing/confirm", to: "pricing#confirm"
  get  "pricing/success", to: "pricing#success"
  get  "pricing/fail",    to: "pricing#fail"
  post "pricing/mock_success", to: "pricing#mock_success"

  # Admin routes
  namespace :admin do
    root to: "dashboard#index"
    resources :dashboard, only: [ :index ]
    resources :users, only: [ :index, :show, :edit, :update ]
    resources :cover_letters, only: [ :index, :show, :destroy ]
    resources :payments, only: [ :index, :show ]
    get "referrals", to: "referrals#index"
    resource :analytics, only: [ :show ]
    resource :settings, only: [ :show ]
  end

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
  get "letter", to: "home#letter"

  # Companies routes
  resources :companies do
    member do
      post "crawl"
    end
    collection do
      get "search"
    end
  end

  # Articles routes for news crawling
  resources :articles, only: [ :index, :show ]

  # Cover Letters routes for AI analysis
  resources :cover_letters, only: [ :index, :new, :create, :destroy ] do
    collection do
      get "interactive"
      post "start_interactive"
      post "send_message"
      post "save_interactive"
      post "save_to_profile"
      post "get_ai_suggestion"
      get "load_profile_data"
      post "update_profile_from_chat"
      post "analyze_pdf"
      post "analyze_text"
      post "generate_final"
      get "advanced"
      get "analyze_advanced"
      post "analyze_advanced"
      # GPT-5 심층 분석 - 사용하지 않음
      # get 'deep_analysis'
      # post 'perform_deep_analysis'
      get "job_posting"
      post "analyze_job_posting"
      get "job_posting_text"
      post "analyze_job_text"
      get "bookmarklet"
      get "ontology_input"
      get "ontology_analysis"
      post "ontology_analysis"
      get "intelligent_analysis"
      post "perform_intelligent_analysis"
      get "integrated_analysis"
      post "perform_integrated_analysis"
      get "integrated_analysis_demo"
      get "saved_job_analyses"
      get "view_job_analysis/:id", to: "cover_letters#view_job_analysis", as: "view_job_analysis"
      post "save_job_analysis/:id", to: "cover_letters#save_job_analysis", as: "save_job_analysis"
      delete "delete_job_analysis/:id", to: "cover_letters#delete_job_analysis", as: "delete_job_analysis"
      get "load_job_analysis", to: "cover_letters#load_job_analysis"
      get "company_analysis", to: "cover_letters#company_analysis"
      post "analyze_company", to: "cover_letters#analyze_company"
      post "analyze_company_python", to: "cover_letters#analyze_company_python"
      get "company_analysis_result/:id", to: "cover_letters#company_analysis_result", as: "company_analysis_result"
      post "save_company_analysis/:id", to: "cover_letters#save_company_analysis", as: "save_company_analysis"
      delete "delete_company_analysis/:id", to: "cover_letters#delete_company_analysis", as: "delete_company_analysis"
      get "saved_company_analyses", to: "cover_letters#saved_company_analyses"
      get "guide", to: "cover_letters#guide"
    end
    member do
      # get 'deep_analysis_result' # GPT-5 심층 분석 - 사용하지 않음
      post "rewrite_with_feedback"
      get "rewrite_result"
      post "save_analysis"
      delete "unsave_analysis"
      get "analyzing"
      post "start_analysis"
    end
  end

  # Show route 별도 정의 (collection routes와 충돌 방지)
  get "cover_letters/:id", to: "cover_letters#show", as: "cover_letter_show", constraints: { id: /\d+/ }
end
