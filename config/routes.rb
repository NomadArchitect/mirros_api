# frozen_string_literal: true

# For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html

Rails.application.routes.draw do
  mount ActionCable.server => '/cable'

  jsonapi_resources :widgets do
    jsonapi_related_resources :widget_instances
    jsonapi_links :widget_instances
    jsonapi_related_resource :group
    jsonapi_links :group
  end

  jsonapi_resources :sources do
    jsonapi_related_resources :source_instances
    jsonapi_related_resources :groups
  end

  jsonapi_resources :widget_instances do
    jsonapi_related_resources :source_instances
    jsonapi_related_resources :instance_associations
    jsonapi_related_resource :widget
    jsonapi_related_resource :group
    jsonapi_related_resource :board
  end

  jsonapi_resources :source_instances do
    jsonapi_related_resource :source
    jsonapi_related_resources :widget_instances
  end

  jsonapi_resources :instance_associations

  jsonapi_resources :groups do
    jsonapi_related_resources :sources
    jsonapi_related_resources :widgets
  end
  jsonapi_resources :settings, only: %i[index show update]

  jsonapi_resources :boards do
    jsonapi_related_resources :widget_instances
    jsonapi_links :widget_instances
    jsonapi_related_resources :rules
  end

  jsonapi_resources :rules

  # File uploads
  resources :uploads
  resources :backgrounds

  # Non-resourceful routes for controlling the system
  get 'assets/:extension_type/:extension/:asset_type/:file', to: 'assets#show', constraints: { file: /.*/ }
  get 'system/fetch_extensions/:type', to: 'system#fetch_extensions'

  get 'system/status', to: 'system#status'
  post 'system/run_setup', to: 'system#run_setup' # TODO: maybe clean those up
  get 'system/reset', to: 'system#reset'
  get 'system/reboot', to: 'system#reboot'
  get 'system/shut_down', to: 'system#shut_down'
  get 'system/reload_browser', to: 'system#reload_browser'
  get 'system/backup', to: 'system#backup_settings'
  post 'system/restore_backup', to: 'system#restore_settings'
  get 'system/logs/:logfile', to: 'system#fetch_logfile'
  get 'system/report', to: 'system#generate_system_report'
  post 'system/report/send', to: 'system#send_debug_report'
  post 'system/log_client_error', to: 'system#log_client_error'

  match 'system/control/:category/:command', to: 'system#setting_execution', via: %i[get patch]
  # FIXME: toggle_lan expects a parameter https://guides.rubyonrails.org/routing.html#http-verb-constraints

  if Rails.const_defined? 'Server'
    Source.all.each do |source|
      engine = source.engine_class

      mount engine, at: "/#{source.id}" unless engine.config.paths['config/routes.rb'].existent.empty?
    end

    Widget.all.each do |widget|
      engine = widget.engine_class

      mount engine, at: "/#{widget.id}" unless engine.config.paths['config/routes.rb'].existent.empty?
    end
  end
end
