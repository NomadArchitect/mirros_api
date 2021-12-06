class RestartBrowserJob < ApplicationJob
  queue_as :system

  def perform(*_args)
    System.reload_browser
  end
end
