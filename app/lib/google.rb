module Google
  class Engine
    def self.schedule_rate
      '5m'
    end

    def refresh
      "I refresh the data for #{self.class} every #{self.class.schedule_rate}"
    end
  end
end
