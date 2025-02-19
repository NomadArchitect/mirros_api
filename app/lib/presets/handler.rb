# frozen_string_literal: true

module Presets
  # Handles creating the default board widget and source instances.
  class Handler
    ALLOWED_IN_LOCAL_NETWORK_MODE = %w[clock current_date network qrcode text_field]

    def self.run(defaults_file_path)
      return if WidgetInstance.count.positive?

      handler = new defaults_file_path
      ActiveRecord::Base.transaction do
        handler.create_widget_instances
        handler.create_default_cal_instances
        handler.create_default_feed_instances
      end
    end

    # @param [Object] defaults_file_path  Path to a valid defaults definition file.
    def initialize(defaults_file_path)
      @defaults = YAML.load_file(defaults_file_path).with_indifferent_access

      configured_locale = ::Setting.value_for('system_language')&.slice(0, 2)
      I18n.locale = configured_locale&.present? ? configured_locale.to_sym : :en

      if System.local_network_mode_enabled?
        @defaults['widget_instances'].select! { |extension, _config| ALLOWED_IN_LOCAL_NETWORK_MODE.include? extension }
        @defaults.delete 'source_instances'
        @defaults['widget_instances']['text_field'].deep_merge!({ configuration: { content: I18n.t('setup.local_network_mode.config.text_field') } })
      end
    end

    # Creates the default widget instances, based on the current display layout.
    def create_widget_instances
      orientation = SystemState.dig(variable: 'client_display', key: 'orientation') || 'portrait' # rubocop:disable Style/SingleArgumentDig
      default_board = Board.find_by(title: 'default')
      instances = []
      @defaults['widget_instances'].each do |slug, config|
        instances << config.merge(
          { widget: Widget.find_by(slug: slug), position: config['position'][orientation], board: default_board })
      end
      WidgetInstance.create(instances)
    end

    # Creates the default holiday calendar configuration.
    # @see SystemController.create_widget_instances must run before to create the widget instance.
    def create_default_cal_instances
      return if @defaults['source_instances'].nil?

      locale = Setting.value_for(:system_language) || 'enGb'
      calendar_settings = default_holiday_calendar(locale)

      calendar_source = SourceInstance.new(
        source: Source.find_by(slug: 'ical'),
        configuration: { "url": calendar_settings[:url] }
      )
      calendar_source.save!(validate: false)
      calendar_source.update(
        options: [
          { uid: calendar_source.options.first['uid'], display: calendar_settings[:title] }
        ],
        title: calendar_settings[:title]
      )

      calendar_widget = WidgetInstance.find_by(widget_id: 'calendar_event_list')
      calendar_widget.update(title: calendar_settings[:title])
      InstanceAssociation.create!(
        configuration: {
          "chosen": [calendar_source.options.first['uid']]
        },
        group: Group.find_by(slug: 'calendar'),
        widget_instance: calendar_widget,
        source_instance: calendar_source
      )
    rescue StandardError => e
      Rails.logger.error "Error during calendar instance creation: #{e.message}"
    end

    def create_default_feed_instances
      return if @defaults['source_instances'].nil?

      locale = Setting.value_for(:system_language).nil? ? 'enGb' : Setting.value_for(:system_language)
      newsfeed_source = SourceInstance.new(
        source: Source.find_by(slug: 'rss_feeds'),
        title: 'glancr: Welcome Screen',
        configuration: {
          "feedUrl": "https://api.glancr.de/welcome/mirros-welcome-#{locale}.xml"
        },
        options: [
          { uid: "https://api.glancr.de/welcome/mirros-welcome-#{locale}.xml",
            display: 'glancr: Welcome Screen' }
        ]
      )
      newsfeed_source.save!(validate: false)

      InstanceAssociation.create!(
        configuration: { "chosen": ["https://api.glancr.de/welcome/mirros-welcome-#{locale}.xml"] },
        group: Group.find_by(slug: 'newsfeed'),
        widget_instance: WidgetInstance.find_by(widget_id: 'ticker'),
        source_instance: SourceInstance.find_by(source_id: 'rss_feeds')
      )
    rescue StandardError => e
      Rails.logger.error "Error during calendar instance creation: #{e.message}"
    end

    private

    # Generates locale-dependent configuration for the default holiday calendar iCal source instance.
    # @param [string] locale A valid system locale, @see app/lib/setting_options.yaml at system_language
    def default_holiday_calendar(locale)
      yaml = @defaults['source_instances']['holiday_calendar']
      {
        url: yaml['configuration']['url'] % yaml['locale_fragments'][locale],
        title: yaml['configuration']['title'] % yaml['titles'][locale]
      }
    end
  end
end
