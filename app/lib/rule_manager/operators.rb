module RuleManager
  module Operators
    class Base
      def self.evaluate(_field, _value)
        Rails.logger.warn 'Implement `evaluate(field, value)` in your operator class!'
        false
      end

      def self.as_json
        { type: :base, value: :text }
      end
    end

    class NumericBase < Base
      def self.parse(value)
        Integer(value) || Float(value)
      end

      def self.as_json
        { type: :numeric, value: :number }
      end
    end

    class LessThan < NumericBase
      def self.evaluate(field, value)
        field < value
      end
    end

    class LessThanOrEqualTo < NumericBase
      def self.evaluate(field, value)
        field <= value
      end
    end

    class GreaterThan < NumericBase
      def self.evaluate(field, value)
        field > value
      end
    end

    class GreaterThanOrEqualTo < NumericBase
      def self.evaluate(field, value)
        field >= value
      end
    end

    class Range < NumericBase
      def self.parse(value)
        { start: Integer(value['start']), end: Integer(value['end']) }
      end

      def self.evaluate(field, value)
        field.between?(value[:start], value[:end])
      end

      def self.as_json
        { type: :range, values: { start: :number, end: :number } }
      end

    end
  end
end
