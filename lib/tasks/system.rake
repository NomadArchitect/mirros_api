# frozen_string_literal: true

namespace :system do
  desc 'Reload the browser snap'
  task reload_browser: [:environment] do |_task, _args|
    next unless ENV['SNAP']

    System.reload_browser
  end

  desc 'Set the StateCache.updating attribute'
  task :set_snap_update_status, %i[snap_update_status] => [:environment] do |_task, args|
    next unless ENV['SNAP']

    unless %w[pre-refresh post-refresh].include?(args[:snap_update_status])
      raise ArgumentError, "#{args} given, must be one of [pre-refresh, post-refresh]"
    end

    SystemState.find_or_initialize_by(variable: 'snap_refresh_status')
               .update(value: args[:snap_update_status])
    System.push_status_update
  end
end
