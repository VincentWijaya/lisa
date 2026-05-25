Rails.application.routes.draw do
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

  resources :works, only: [] do
    member do
      get :barcode_label
    end
  end

  resources :specimens, only: [] do
    member do
      get :barcode_labels
    end
  end
end
