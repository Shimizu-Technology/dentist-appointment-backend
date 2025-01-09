# File: config/routes.rb

Rails.application.routes.draw do
  namespace :api do
    namespace :v1 do
      # Sessions / Auth
      post '/login', to: 'sessions#create'

      # Public self-signup route
      post '/signup', to: 'signups#create'
      # e.g., a user can create their account with email + password

      # Finish invitation
      patch '/invitations/finish', to: 'invitations#finish'

      # Appointments
      resources :appointments, only: [:index, :create, :show, :update, :destroy] do
        collection do
          get :day_appointments
        end
        member do
          patch :check_in  # Toggle/check-in an appointment
        end
      end

      # Dependents
      resources :dependents, only: [:index, :create, :update, :destroy]

      # Appointment Types
      resources :appointment_types

      # Dentists
      resources :dentists, only: [:index, :show, :create, :update, :destroy] do
        member do
          get :availabilities     # GET /api/v1/dentists/:id/availabilities
          post :upload_image      # POST /api/v1/dentists/:id/upload_image
        end
      end

      # Specialties
      resources :specialties

      # Users (admin usage)
      resources :users, only: [:create, :index, :update, :destroy] do
        collection do
          patch :current   # Update current user
          get :search      # Search users
        end
        member do
          patch :promote   # Promote user to admin
        end
      end

      # Closed Days
      resources :closed_days, only: [:index, :create, :destroy]

      # Schedules => single resource (singular)
      resource :schedule, only: [:show, :update], controller: :schedules

      # Dentist Unavailabilities
      resources :dentist_unavailabilities, only: [:create, :update, :destroy]
    end
  end
end
