module Wunderlist
  class Engine
    def self.schedule_rate
      '30s'
    end

    def refresh
      "I refresh the data for #{self.class} every #{self.class.schedule_rate}"
    end
  end
end
