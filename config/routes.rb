Rails.application.routes.draw do

  get 'pages/home'

  root 'pages#home'

  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html

  resources :instances
  resources :source_instances
  resources :widget_instances
  resources :widgets
  resources :sources
  resources :categories
  resources :groups

  mount Netatmo::Engine => "/api/netatmo"
  # mount Blorgh::Engine => "/api/modules"

end
