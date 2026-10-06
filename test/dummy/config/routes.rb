Rails.application.routes.draw do
  mount Ticket::Engine => "/ticket"
  root "pages#show"
  get "sign_in", to: "pages#sign_in"
end
