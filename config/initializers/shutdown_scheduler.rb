# frozen_string_literal: true

if Rails.const_defined? 'Server'
  shutdown_time = Setting.value_for(:system_scheduleshutdown)
  if shutdown_time.present?
    SettingExecution::System.schedule_shutdown shutdown_time
    Rails.logger.info "Scheduled shutdown at #{shutdown_time.to_time}"
  elsif StateCache.configured_at_boot || System.setup_completed?
    Scheduler.daily_reboot
  end
end
