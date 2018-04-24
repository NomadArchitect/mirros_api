module Todoist
  class Engine
    def self.schedule_rate
      '1m'
    end

    def refresh
      "I refresh the data for #{self.class} every #{self.class.schedule_rate}"
    end
  end
end
