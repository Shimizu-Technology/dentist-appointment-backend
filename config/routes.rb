# File: config/routes.rb

Rails.application.routes.draw do
  namespace :api do
    namespace :v1 do
      # Sessions / Auth
      post   '/login',               to: 'sessions#create'
      post   '/signup',              to: 'signups#create'
      patch  '/invitations/finish',  to: 'invitations#finish'

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

      # NORMAL user routes for child users => /api/v1/users/my_children
      # (IMPORTANT: define this BEFORE the main users resource)
      namespace :users do
        resources :my_children, only: [:index, :create, :update, :destroy]
      end

      # Users (admin-only for full CRUD) plus custom :current and :search
      resources :users, only: [:create, :index, :show, :update, :destroy] do
        collection do
          # explicitly define GET and PATCH for "/users/current"
          get  :current    # => users#current (GET)
          patch :current   # => users#current (PATCH)
          get  :search
        end
        member do
          patch :promote
          patch :resend_invitation
        end
      end

      # Closed Days
      resources :closed_days, only: [:index, :create, :destroy]

      # Single resource for Schedules
      resource :schedule, only: [:show, :update], controller: :schedules

      # Dentist Unavailabilities
      resources :dentist_unavailabilities, only: [:index, :create, :update, :destroy]

      # Day-of-week ClinicDaySettings
      resources :clinic_day_settings, only: [:index, :update]

      # Admin routes for child users => /api/v1/admin/children
      namespace :admin do
        resources :children, only: [:index, :create, :update, :destroy]
      end
    end
  end
end
