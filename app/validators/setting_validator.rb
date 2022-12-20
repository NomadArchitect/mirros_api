# frozen_string_literal: true

# Custom validator for Setting models.
class SettingValidator < ActiveModel::EachValidator
  # FIXME: Can we break this down without lots of argument passing?
  def validate_each(record, attr, value)
    msg = case record.slug
          when 'system_timezone'
            "#{value} is not a valid timezone!" if ActiveSupport::TimeZone[value.to_s].nil?

          when /system_backgroundcolor|system_fontcolor/ # Check for valid hex color values.
            "#{value} is not a valid CSS color!" unless value.match?(/^#[0-9A-F]{6}$/i)

          when 'system_activeboard'
            "Cannot find board with ID #{value}" unless Board.exists?(value)

          when 'personal_email'
            unless value =~ /\A([\w+\-].?)+@[a-z\d\-]+(\.[a-z]+)*\.[a-z]+\z/i
              "#{value} is not a valid email address"
            end

          when 'system_boardrotation'
            if Setting.find_by(slug: 'system_multipleboards')&.value.eql?('on')
              opts = record.options
              "#{value} is not a valid option for #{attr}, options are: #{opts.keys}" unless opts.key?(value)
            else
              'Please enable `multiple boards` first'
            end
          when 'system_boardrotationinterval'
            'Only values between 1 and 120 are allowed' unless value.to_i.between?(1, 120)
          when 'system_scheduleshutdown'
            begin
              if value.present? && value.to_time.blank?
                "#{value} is not a valid time of day. Schema is 'hh:mm'"
              end
            rescue StandardError
              "#{value} is not a valid time of day. Schema is 'hh:mm'"
            end

          else
            opts = record.options
            # Check if the option is valid, or if this setting has no options.
            unless opts.key?(value) || opts.empty?
              "#{value} is not a valid option for #{attr}, options are: #{opts.keys}"
            end
          end
    record.errors.add(attr, msg) unless msg.nil?
  end
end
