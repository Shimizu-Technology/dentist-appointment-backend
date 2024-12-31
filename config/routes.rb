Rails.application.routes.draw do
  get "pages/home"
  # remove or comment out the duplicate here
  # devise_for :users

  # Define your application routes per the DSL...
  get "up" => "rails/health#show", as: :rails_health_check
  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest

  # The correct Devise routes
  devise_for :users

  root to: "pages#home"
end
