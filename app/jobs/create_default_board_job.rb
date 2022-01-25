class CreateDefaultBoardJob < ApplicationJob
  queue_as :system

  after_perform :complete_setup

  def perform(*_args)
    return if WidgetInstance.count.positive?

    raise 'System not online' unless System.online?

    Presets::Handler.run Rails.root.join('app/lib/presets/default_extensions.yml')
  end

  def complete_setup
    # FIXME: This is a temporary workaround to differentiate between
    # initial setup before first connection attempt and subsequent network problems.
    # Remove once https://gitlab.com/glancr/mirros_api/issues/87 lands
    StateCache.put :configured_at_boot, true
    StateCache.put :running_setup_tasks, false
  end
end
