Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html

  resources :instances
  resources :source_instances
  resources :component_instances
  resources :components
end
