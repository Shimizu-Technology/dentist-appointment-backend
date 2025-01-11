# File: config/routes.rb
Rails.application.routes.draw do
  namespace :api do
    namespace :v1 do
      # Sessions / Auth
      post '/login', to: 'sessions#create'
      post '/signup', to: 'signups#create'
      patch '/invitations/finish', to: 'invitations#finish'

      # Appointments
      resources :appointments, only: [:index, :create, :show, :update, :destroy] do
        collection do
          get :day_appointments
        end
        member do
          patch :check_in
        end
      end

      # Appointment Reminders
      resources :appointment_reminders, only: [:index, :update]

      # Dependents for the **current user** scenario
      resources :dependents, only: [:index, :create, :update, :destroy]

      # Appointment Types
      resources :appointment_types

      # Dentists
      resources :dentists, only: [:index, :show, :create, :update, :destroy] do
        member do
          get :availabilities
          post :upload_image
        end
      end

      # Specialties
      resources :specialties

      # Nested dependents for an admin controlling a specific user:
      resources :users, only: [:create, :index, :update, :destroy] do
        # This route means => POST /api/v1/users/:user_id/dependents
        resources :dependents, only: [:create, :update, :destroy], module: :users

        collection do
          patch :current
          get :search
        end
        member do
          patch :promote
        end
      end

      # Closed Days
      resources :closed_days, only: [:index, :create, :destroy]

      # Schedules => single resource
      resource :schedule, only: [:show, :update], controller: :schedules

      # Dentist Unavailabilities
      resources :dentist_unavailabilities, only: [:index, :create, :update, :destroy]

      # Day-of-week ClinicDaySettings
      resources :clinic_day_settings, only: [:index, :update]
    end
  end
end
