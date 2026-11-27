Rails.application.routes.draw do
  get "/up" => "up#show"
  root "pages#home"
end