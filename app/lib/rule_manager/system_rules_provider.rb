module RuleManager
  class SystemRulesProvider
    def self.rules
      {
        timeOfDay: {
          operators: {
            before: Operators::LessThan,
            after: Operators::GreaterThanOrEqualTo,
            between: Operators::Range
          }
        }
      }

    end

    def self.time_of_day
      Time.current.hour
    end
  end
end
