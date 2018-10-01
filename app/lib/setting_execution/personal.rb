# frozen-string-literal: true

require 'os'

module SettingExecution

  # Provides methods to apply settings in the personal namespace.
  class Personal

    def self.send_setup_email
      send_email(:setup)
    end

    def self.send_change_email
      send_email(:change)
    end

    def self.send_reset_email
      send_email(:reset)
    end

    def self.send_email(type)
      host = "https://#{System::API_HOST}/mailer/mail/"
      body = compose_body
      body[:type] = type
      res = HTTParty.post(
        host,
        headers: { 'Content-Type': 'application/json' },
        body: body.to_json
      )
      # TODO: Add error handling
      res.body unless res.code != 200
    end
    private_class_method :send_email

    def self.compose_body
      {
        name: Setting.find_by_slug('personal_name').value,
        email: Setting.find_by_slug('personal_email').value,
        language: convert_language_tag(Setting.find_by_slug('system_language').value),
        localip: System.current_ip
      }
    end
    private_class_method :compose_body

    # Convert camelcase language_territory tag to POSIX-style tag.
    def self.convert_language_tag(camel_tag)
      camel_tag.underscore.gsub(/(?<lang>[a-z]{2})_(?<locale>[a-z]{2})/) do
        "#{$LAST_MATCH_INFO[:lang]}_#{$LAST_MATCH_INFO[:locale].upcase}"
      end
    end
    private_class_method :convert_language_tag
  end
end
