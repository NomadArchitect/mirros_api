Rails.application.routes.draw do
  mount Netatmo::Engine => "/api/netatmo"
end

Netatmo::Engine.routes.draw do
  resources :entries
  root "entries#index"
end
