Netatmo::Engine.routes.draw do
  resources :entries
  root "entries#index"
end
