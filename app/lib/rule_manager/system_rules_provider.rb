module RuleManager
  class SystemRulesProvider
    def self.rules
      {
        timeOfDay: {
          operators: {
            before: Operators::LessThan,
            after: Operators::GreaterThanOrEqualTo,
            between: Operators::RangeExcludingEnd
          }
        },
        dateAndTime: {
          operators: {
            betweenDates: Operators::BetweenDates,
          }
        }
      }

    end

    def self.time_of_day
      Time.current.hour
    end

    def self.date_and_time
      Time.current
    end
  end
end
