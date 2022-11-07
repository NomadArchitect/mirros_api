Rails.configuration.after_initialize do
  I18n.default_locale = ::Setting.value_for('system_language')&.slice(0, 2)&.to_sym || :en
end
