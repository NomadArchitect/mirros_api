# frozen_string_literal: true

# Sends the post-setup welcome email.
class SendWelcomeMailJob < ApplicationJob
  queue_as :default

  # Sends a welcome email if setup is completed and the SystemState has not been set yet.
  def perform(*_args)
    return unless System.setup_completed?
    return if SystemState.find_by(variable: :welcome_mail_sent)&.value.eql? true

    SettingExecution::Personal.send_setup_email

    SystemState.find_or_initialize_by(variable: :welcome_mail_sent).update(value: true)
  end
end
