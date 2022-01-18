# frozen_string_literal: true

module NetworkManager
  # Helpers for NetworkManager-related routines. Used in SignalListeners and in Commands.
  module Helpers
    def retry_wrap(max_attempts: 3, &block)
      attempts = 0
      begin
        yield block
      rescue DBus::Error => e
        # Rails.logger.warn "#{__method__} #{e.message}"
        sleep 1
        retry if (attempts += 1) <= max_attempts

        raise e
      end
    end
  end
end
