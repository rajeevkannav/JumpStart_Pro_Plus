Rails.application.routes.draw do
  resource :session
  resource :sudo, only: [ :new, :create ]
  resources :passwords, param: :token
  resource :registration, only: [ :new, :create ]
  resource :email_confirmation, only: [ :show, :create ]
  resources :accounts do
    resource :switch, only: :create, module: :accounts
  end
  get "account", to: "accounts#show", as: :current_account
  # Older form-posted switch (account_id in the body); same controller.
  post "account/switch", to: "accounts/switches#create", as: :account_selection
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
