# frozen_string_literal: true

return unless Rails.const_defined? 'Server'

shutdown_time = Setting.value_for(:system_scheduleshutdown)
if shutdown_time.present?
  SettingExecution::System.schedule_shutdown shutdown_time
  Rails.logger.info "Scheduled shutdown at #{shutdown_time.to_time}"
end
