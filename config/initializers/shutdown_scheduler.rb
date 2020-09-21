# frozen_string_literal: true

if Rails.const_defined? 'Server'
  shutdown_time = SettingsCache.s[:system_scheduleshutdown]
  if shutdown_time.present?
    SettingExecution::System.schedule_shutdown shutdown_time
    Rails.logger.info "Scheduled shutdown at #{shutdown_time.to_time}"
  end
end
