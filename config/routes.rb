Rails.application.routes.draw do

  get 'pages/home'
  root 'pages#home'

  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html

  jsonapi_resources :widgets do
    jsonapi_related_resources :widget_instances
    jsonapi_related_resources :services
  end
  jsonapi_resources :sources do
    jsonapi_related_resources :source_instances
  end

  jsonapi_resources :services

  # jsonapi_resources :categories
  # jsonapi_resources :groups

end
