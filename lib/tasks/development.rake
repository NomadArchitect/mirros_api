# frozen_string_literal: true

namespace :mirros do
  namespace :dev do
    desc 'Perform an automated setup routine with pre-set settings'
    task :run_setup, %i[orientation user email] => :environment do |_task, args|
      email = args[:email] || `git config --get user.email`.chomp!
      name = args[:user] || `git config --get user.name`.chomp!
      p "Using #{name} / #{email} for setup"
      raise ArgumentError if name.empty? || email.empty?

      orientation = args[:orientation] || 'portrait'
      p "Using #{orientation} mode"

      Setting.find_by(slug: 'system_language').update!(value: 'enGb')
      Setting.find_by(slug: 'system_timezone').update!(value: 'Europe/Berlin')
      Setting.find_by(slug: 'personal_privacyConsent').update!(value: 'yes')
      Setting.find_by(slug: 'network_connectiontype').update!(value: 'lan')
      Setting.find_by(slug: 'personal_email').update!(value: email)
      Setting.find_by(slug: 'personal_name').update!(value: name)

      EnvironmentVariable.find_or_initialize_by(variable: 'client_display')
                 .update(
                   value: {
                     orientation: orientation,
                     width: orientation.eql?('portrait') ? 1080 : 1920,
                     height: orientation.eql?('portrait') ? 1920 : 1080
                   }
                 )

      # Test online status
      SettingExecution::Network.send(:validate_connectivity)

      # System has internet connectivity, complete seed and send setup mail
      SettingExecution::Personal.send_setup_email
      Presets::Handler.run Rails.root.join('app/lib/presets/default_extensions.yml')
      puts 'Setup complete'
    end
  end
end
