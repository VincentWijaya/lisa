Rails.application.routes.draw do
  # Authentication
  resource :session, only: [:new, :create, :destroy]
  get "login", to: "sessions#new", as: :login
  delete "logout", to: "sessions#destroy", as: :logout

  namespace :admin do
      resources :examinations
      resources :examination_results
      resources :reference_rules
      resources :specimens
      resources :works
      resources :users
      resources :roles

      root to: "examinations#index"
    end
  get "up" => "rails/health#show", as: :rails_health_check

  namespace :api do
    namespace :v1 do
      post 'analyzer/results', to: 'analyzer#ingest'
      resources :examinations, only: [:index]
      resources :specimens, only: [:create, :show, :index]
      resources :works, only: [:show, :index] do
        member do
          patch :validate
          patch :verify
          patch :cancel
          post :results
          get :barcode_label
        end
      end
    end
  end

  resources :works, only: [:index, :show, :update] do
    member do
      patch :validate_work
      patch :verify_work
      patch :cancel_work
      get :barcode_label
      post :add_result
      post :upsert_results
      post :scan_validate
    end
    resources :examination_results, only: [:update, :destroy], module: :works do
      member do
        patch :verify
      end
    end
  end

  resources :specimens, only: [:index, :show, :new, :create, :update] do
    member do
      get :barcode_labels
      get :print_report
      get :send_report_form
      post :send_report
    end
  end

  get "bank-darah", to: "menus#show", defaults: { menu_key: "bank_darah" }, as: :bank_darah
  get "mikrobiologi", to: "menus#show", defaults: { menu_key: "mikrobiologi" }, as: :mikrobiologi
  get "patologi-anatomi", to: "menus#show", defaults: { menu_key: "patologi_anatomi" }, as: :patologi_anatomi
  get "inventori", to: "menus#show", defaults: { menu_key: "inventori" }, as: :inventori
  get "monitor-qc", to: "menus#show", defaults: { menu_key: "monitor_qc" }, as: :monitor_qc
  get "laporan", to: "menus#show", defaults: { menu_key: "laporan" }, as: :laporan

  root to: "dashboard#index"
end
