Rails.application.routes.draw do
  root to: "pages#home"
  devise_for :users

  resources :appointments
  resources :dependents
  resources :appointment_types
  resources :dentists, only: [:index, :show] # or full CRUD if admins can manage them
end
