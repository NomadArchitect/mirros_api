module Todoist
  class Hooks
    REFRESH_INTERVAL = '5m'.freeze

    # @return [String]
    def self.refresh_interval
      REFRESH_INTERVAL
    end

    def refresh
      "I refresh the data for #{self.class} every #{self.class.schedule_rate}"
    end
  end
end
