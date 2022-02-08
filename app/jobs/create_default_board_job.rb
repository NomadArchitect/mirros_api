class CreateDefaultBoardJob < ApplicationJob
  queue_as :system

  after_perform :complete_setup

  def perform(*_args)
    return if WidgetInstance.count.positive?

    raise 'System not online' unless System.online?

    # rubocop:disable Style/SingleArgumentDig
    # Use different defaults for smaller screens that have less than 12 columns.
    orientation = SystemState.dig(variable: 'client_display', key: 'orientation') || 'portrait'
    display_width = SystemState.dig(variable: 'client_display', key: 'width') || 1080
    # rubocop:enable Style/SingleArgumentDig
    standard_width = orientation.eql?('portrait') ? 1080 : 1920
    preset = display_width < standard_width ? 'app/lib/presets/default_small_screen.yml' : 'app/lib/presets/default_extensions.yml'

    Presets::Handler.run Rails.root.join(preset)
  end

  def complete_setup
    # FIXME: This is a temporary workaround to differentiate between
    # initial setup before first connection attempt and subsequent network problems.
    # Remove once https://gitlab.com/glancr/mirros_api/issues/87 lands
    StateCache.put :configured_at_boot, true
    StateCache.put :running_setup_tasks, false
  end
end
