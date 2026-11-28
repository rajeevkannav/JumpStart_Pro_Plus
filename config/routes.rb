Rails.application.routes.draw do
  resource :session
  resource :sudo, only: [ :new, :create ]
  resources :passwords, param: :token
  resource :registration, only: [ :new, :create ]
  resource :email_confirmation, only: [ :show, :create ]
  resources :accounts
  namespace :settings do
    resources :sessions, only: [ :index, :destroy ] do
      delete :others, on: :collection, action: :destroy_others
    end
    get "account/delete", to: "account_deletions#new", as: :new_account_deletion
    post "account/delete", to: "account_deletions#create", as: :account_deletion
  end
  get "up" => "rails/health#show", as: :rails_health_check
  root "pages#home"
end
