Rails.application.routes.draw do
  resource :session
  resources :passwords, param: :token
  resource :registration, only: [ :new, :create ]
  resource :email_confirmation, only: [ :show, :create ]
  get "up" => "rails/health#show", as: :rails_health_check
  root "pages#home"
end
