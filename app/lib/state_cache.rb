# frozen_string_literal: true

# Cache for application state
class StateCache

  VALID_STATE_KEYS = %i[
    resetting
    setup_complete
    registered
    running_setup
  ].freeze

  def self.refresh
    init = {}
    VALID_STATE_KEYS.each { |k| init.store k.to_s, initial_value(k) }
    Rails.cache.write_multi init, namespace: :state
  end

  def self.get(key)
    Rails.cache.fetch key, namespace: :state do
      initial_value(key)
    end
  end

  def self.put(key, value)
    Rails.cache.write key, value, namespace: :state
    ::System.push_status_update
  end

  def self.initial_value(key = nil)
    case key
    when :resetting
      false
    when :setup_complete
      System.setup_completed?
    when :registered
      RegistrationHandler.new.product_key_valid?
    else
      nil
    end
  end

  def self.as_json
    Rails
      .cache
      .read_multi(*VALID_STATE_KEYS, namespace: :state)
  end
end
