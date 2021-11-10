# frozen_string_literal: true

# In-memory cache for application state
class StateCache
  include NetworkManager::Constants

  VALID_STATE_KEYS = %i[
    resetting
    nm_state
    setup_complete
    configured_at_boot
    online
    connectivity
    connectivity_check_available
    network_status
    primary_connection
    networks
    registered
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

    if key.to_sym.eql?(:nm_state) && value.eql?(NmState::CONNECTING)
      # NetworkManager sometimes sends CONNECTING state over DBus *after* it has
      # activated a connection with CONNECTED_GLOBAL. This forces a manual refresh
      # after 30 seconds to avoid a stale state.
      ForceNmStateCheckJob.set(wait: 30.seconds).perform_later
    end

    return unless key.to_sym.eql?(:connectivity) && value.eql?(NmConnectivityState::LIMITED)

    force_connectivity_check
  end

  def self.initial_value(key = nil)
    case key
    when :resetting
      false
    when :nm_state
      OS.linux? ? NetworkManager::Commands.instance.state : nil
    when :setup_complete, :configured_at_boot
      System.setup_completed?
    when :online
      System.online?
    when :connectivity
      if OS.linux?
        state = NetworkManager::Commands.instance.connectivity
        force_connectivity_check if state.eql?(NmConnectivityState::LIMITED)
        state
      else
        NmConnectivityState::UNKNOWN
      end
    when :connectivity_check_available
      OS.linux? ? NetworkManager::Commands.instance.connectivity_check_available? : nil
    when :network_status
      SettingExecution::Network.wifi_signal_status
    when :primary_connection
      primary_path = if OS.linux?
                       NetworkManager::Commands.instance.primary_connection
                     else
                       '/'
                     end
      if primary_path.eql?('/')
        nil
      else
        NmNetwork.find_by(active_connection_path: primary_path)&.public_info
      end
    when :networks
      NmNetwork.all.map(&:public_info)
    when :registered
      RegistrationHandler.new.product_key_valid?
    else
      nil
    end
  end

  def self.connectivity_from_dns
    if Resolv::DNS.new.getaddress(::System::API_HOST).to_s.eql?(::System::SETUP_IP)
      NmConnectivityState::PORTAL
    else
      NmConnectivityState::FULL
    end
  rescue StandardError
    NmConnectivityState::NONE
  end

  def self.force_connectivity_check
    job = UpdateConnectivityStatusJob.set(wait: 10.seconds).perform_later check_via_dns: true
    Rails.logger.info "scheduled UpdateConnectivityStatusJob job #{job.provider_job_id} in 10s"
  end

  # @param [Object] ac_path
  # @return [nil]
  def self.schedule_pc_refresh(ac_path)
    if ac_path.eql?('/')
      StateCache.put :primary_connection, nil
    else
      # Use a delayed job to ensure the connection is already persisted with
      # its current active path.
      UpdatePrimaryConnectionJob.set(wait: 10.seconds).perform_later ac_path
    end
  end

  def self.refresh_networks
    put :networks, NmNetwork.all.map(&:public_info)
  end

  def self.as_json
    Rails
      .cache
      .read_multi(*VALID_STATE_KEYS, namespace: :state)
  end
end
