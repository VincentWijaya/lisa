Rails.application.routes.draw do
  namespace :admin do
      resources :examinations
      resources :examination_results
      resources :reference_rules
      resources :specimens
      resources :works

      root to: "examinations#index"
    end
  get "up" => "rails/health#show", as: :rails_health_check

  namespace :api do
    namespace :v1 do
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

  resources :works, only: [:index, :show] do
    member do
      patch :validate_work
      patch :verify_work
      patch :cancel_work
      get :barcode_label
    end
  end

  resources :specimens, only: [:index, :show] do
    member do
      get :barcode_labels
    end
  end

  root to: "dashboard#index"
end
