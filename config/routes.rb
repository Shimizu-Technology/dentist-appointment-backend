Rails.application.routes.draw do
  namespace :api do
    namespace :v1 do
      post '/login', to: 'sessions#create'
      resources :appointments, only: [:index, :create, :show, :update, :destroy]
      resources :dependents, only: [:index, :create, :update, :destroy]
      resources :appointment_types
      resources :dentists, only: [:index, :show]
      # Possibly a Users controller if needed
    end
  end
end
