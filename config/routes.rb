# frozen_string_literal: true

# For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html

Rails.application.routes.draw do

  if Rails.env.development?
    require 'sidekiq/web'
    require 'sidekiq-scheduler/web'
    mount Sidekiq::Web => "/sidekiq"
  end

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

  # Widget routes.
  mount BingTraffic::Engine, at: '/bing_traffic'
  mount CalendarEventList::Engine , at: '/calendar_event_list'
  mount CalendarWeekOverview::Engine, at: '/calendar_week_overview'
  mount CalendarUpcomingEvent::Engine, at: '/calendar_upcoming_event'
  mount Clock::Engine, at: '/clock'
  mount Countdown::Engine, at: '/countdown'
  mount CurrentDate::Engine, at: '/current_date'
  mount Mirros::Widget::EmbedPdf::Engine, at: '/embed_pdf'
  mount FuelPrices::Engine, at: '/fuel_prices'
  mount Idioms::Engine, at: '/idioms'
  mount IpCam::Engine, at: '/ip_cam'
  mount Mirros::Widget::EmbedIframe::Engine, at: '/embed_iframe'
  mount Network::Engine, at: '/network'
  mount OwmCurrentWeather::Engine, at: '/owm_current_weather'
  mount OwmDailyValues::Engine, at: '/owm_daily_values'
  mount OwmForecast::Engine, at: '/owm_forecast'
  mount Pictures::Engine, at: '/pictures'
  mount PublicTransportDepartures::Engine, at: '/public_transport_departures'
  mount Styling::Engine, at: '/styling'
  mount TextField::Engine, at: '/text_field'
  mount Ticker::Engine, at: '/ticker'
  mount Todos::Engine, at: '/todos'
  mount Qrcode::Engine, at: '/qrcode'
  mount VideoPlayer::Engine, at: '/video_player'

  # Source routes.
  mount Ical::Engine, at: '/ical'
  mount Openweathermap::Engine, at: '/openweathermap'
  mount RssFeeds::Engine, at: '/rss_feeds'
  mount IdiomsSource::Engine, at: '/idioms_source'
  mount Sbb::Engine, at: '/sbb'
  mount Todoist::Engine, at: '/todoist'
  mount Vbb::Engine, at: '/vbb'
  mount Mirros::Source::Netatmo::Engine, at: '/netatmo'
  # mount mirros-source-microsoft_todo, at: '/microsoft_todo' FIXME: Engine uses global namespace.
end
