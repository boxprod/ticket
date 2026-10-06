Ticket::Engine.routes.draw do
  resources :reports, only: :create do
    get :screenshot, on: :member
  end
end
