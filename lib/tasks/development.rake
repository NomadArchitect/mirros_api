# frozen_string_literal: true

namespace :dev do
  desc 'Perform an automated setup routine with pre-set settings'
  task run_setup: :environment do
    Setting.find_by(slug: 'system_language').update!(value: 'enGb')
    Setting.find_by(slug: 'system_timezone').update!(value: 'Europe/Berlin')
    Setting.find_by(slug: 'personal_privacyConsent').update!(value: 'yes')
    Setting.find_by(slug: 'network_connectiontype').update!(value: 'lan')
    Setting.find_by(slug: 'personal_email').update!(value: 'tg@glancr.de')
    Setting.find_by(slug: 'personal_name').update!(value: 'Tobias')

    StateCache.s.configured_at_boot = true
    # FIXME: This is a temporary workaround to differentiate between
    # initial setup before first connection attempt and subsequent network problems.
    # Remove once https://gitlab.com/glancr/mirros_api/issues/87 lands

    # Test online status
    ctrl = SystemController.new
    ctrl.send(:online_or_raise)

    # System has internet connectivity, complete seed and send setup mail
    SettingExecution::Personal.send_setup_email

    ctrl.send(:create_default_cal_instances)
    ctrl.send(:create_default_feed_instances)

    puts 'Setup complete'
  end
end
