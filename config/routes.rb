# frozen_string_literal: true

# For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html

Rails.application.routes.draw do
  jsonapi_resources :widgets do
    jsonapi_related_resources :widget_instances
    jsonapi_related_resources :services
    jsonapi_related_resources :groups
  end

  jsonapi_resources :sources do
    jsonapi_related_resources :source_instances
    jsonapi_related_resources :groups
  end

  jsonapi_resources :services

  jsonapi_resources :widget_instances do
    jsonapi_related_resources :source_instances
    jsonapi_related_resources :instance_associations
  end

  jsonapi_resources :source_instances do
    jsonapi_related_resources :record_links
  end

  jsonapi_resources :instance_associations
  jsonapi_resources :groups
  jsonapi_resources :settings, only: %i[index show update]

  get 'templates/:extension/:application', to: 'templates#show'
end
