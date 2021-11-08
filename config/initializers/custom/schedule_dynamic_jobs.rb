# frozen_string_literal: true

return unless Rails.const_defined? 'Server'

shutdown_time = Setting.value_for(:system_scheduleshutdown)
if shutdown_time.present?
  SettingExecution::System.schedule_shutdown shutdown_time
  Rails.logger.info "Scheduled shutdown at #{shutdown_time.to_time}"
elsif StateCache.get(:configured_at_boot) || System.setup_completed?
  Scheduler.daily_reboot
end

# Schedule all source instances for refresh.
SourceInstance.all.each(&:schedule)

RuleManager::Scheduler.init_jobs Setting.value_for(:system_boardrotation)
