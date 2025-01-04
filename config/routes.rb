# config/routes.rb

Rails.application.routes.draw do
  namespace :api do
    namespace :v1 do
      # Sessions / Auth
      post '/login', to: 'sessions#create'

      # Appointments
      resources :appointments, only: [:index, :create, :show, :update, :destroy] do
        collection do
          get :day_appointments
        end
      end

      # Dependents
      resources :dependents, only: [:index, :create, :update, :destroy]

      # Appointment Types
      resources :appointment_types

      # Dentists
      resources :dentists, only: [:index, :show] do
        get :availabilities, on: :member
      end

      # Specialties
      resources :specialties

      # Users (admin can see index, etc.)
      resources :users, only: [:create, :index] do
        collection do
          patch :current       # update current user
          get :search          # search users
        end
        member do
          patch :promote       # promote user to admin
        end
      end

      # Closed Days (block entire days)
      resources :closed_days, only: [:index, :create, :destroy]

      # Schedules (Admin-only) - for global open/close times, etc.
      # GET /api/v1/schedules => schedules#index  (or show)
      # PATCH /api/v1/schedules => schedules#update
      resources :schedules, only: [:index, :update]
    end
  end
end
