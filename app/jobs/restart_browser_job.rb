class RestartBrowserJob < ApplicationJob
  queue_as :default

  def perform(*_args)
    System.reload_browser
  end
end
