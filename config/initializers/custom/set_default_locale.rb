Rails.configuration.after_initialize do
  configured_locale = ::Setting.value_for('system_language')&.slice(0, 2)
  I18n.default_locale = configured_locale&.present? ? configured_locale.to_sym : :en
end
