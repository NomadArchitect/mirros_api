class CreateDefaultBoardJob < ApplicationJob
  queue_as :system

  def perform(*_args)
    return if WidgetInstance.count.positive?

    raise 'System not online' unless System.online?

    Presets::Handler.run Rails.root.join('app/lib/presets/default_extensions.yml')
  end
end
