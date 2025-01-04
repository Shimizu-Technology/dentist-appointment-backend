# config/routes.rb
Rails.application.routes.draw do
  namespace :api do
    namespace :v1 do
      post '/login', to: 'sessions#create'
      resources :appointments, only: [:index, :create, :show, :update, :destroy] do
        collection do
          get :day_appointments
        end
      end
      resources :dependents, only: [:index, :create, :update, :destroy]
      resources :appointment_types
      resources :dentists, only: [:index, :show] do
        get :availabilities, on: :member
      end
      resources :specialties
      resources :users, only: [:create, :index] do
        collection do
          patch :current
          get :search
        end
        member do
          patch :promote
        end
      end
      resources :closed_days, only: [:index, :create, :destroy]
    end
  end
end
