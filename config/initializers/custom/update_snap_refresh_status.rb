# frozen_string_literal: true

return unless Rails.const_defined?('Server')

EnvironmentVariable.find_or_initialize_by(variable: 'snap_refresh_status')
           .update(value: 'post-refresh')

