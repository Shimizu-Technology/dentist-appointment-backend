Rails.application.routes.draw do
  namespace :api do
    namespace :v1 do
      post '/login', to: 'sessions#create'
      
      resources :appointments, only: [:index, :create, :show, :update, :destroy]
      resources :dependents, only: [:index, :create, :update, :destroy]
      resources :appointment_types
      resources :users, only: [:create]
      
      resources :dentists, only: [:index, :show] do
        # GET /api/v1/dentists/:id/availabilities
        get :availabilities, on: :member
      end
    end
  end
end
