# frozen_string_literal: true

if Rails.const_defined?('Server')
  SystemState.find_or_initialize_by(variable: 'snap_refresh_status')
             .update(value: 'post-refresh')
end
