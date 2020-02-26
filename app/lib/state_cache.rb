# frozen_string_literal: true

# In-memory cache for application state
class StateCache
  include ActiveModel::Validations
  include Singleton

  attr_reader :resetting, :nm_state, :setup_complete,
              :configured_at_boot, :online, :connectivity,
              :connectivity_check_available,
              :network_status
  validates :resetting, inclusion: [true, false]

  class << self
    delegate_missing_to :instance
  end

  def initialize
    # FIXME: resetting is a temporary indicator, rework with https://gitlab.com/glancr/mirros_api/issues/87
    @resetting = false
    @nm_state = NetworkManager::Commands.instance.state if OS.linux?
    @setup_complete = System.setup_completed?
    # FIXME: configured_at_boot is a temporary workaround to differentiate between
    # initial setup before first connection attempt and subsequent network problems.
    # Remove once https://gitlab.com/glancr/mirros_api/issues/87 lands
    @configured_at_boot = @setup_complete
    @online = System.online?
    @connectivity = init_connectivity
    if OS.linux?
      @connectivity_check_available = NetworkManager::Commands.instance.connectivity_check_available?
    end
    @network_status = SettingExecution::Network.wifi_signal_status
    @primary_connection = init_primary_connection
    @networks = NmNetwork.all.map(&:public_info)
  end

  def refresh_resetting(status)
    @resetting = status
    ::System.push_status_update
  end

  def refresh_nm_state(status)
    @nm_state = status
    ::System.push_status_update
    return unless status.eql?(NetworkManager::Constants::NmState::CONNECTING)

    # NetworkManager sometimes sends CONNECTING state over DBus *after* it has
    # activated a connection with CONNECTED_GLOBAL. This forces a manual refresh
    # after 30 seconds to avoid a stale state.
    Rufus::Scheduler.singleton.in '30s',
                                  tags: 'force-nm_state-check',
                                  overlap: false do
      state = NetworkManager::Commands.instance.state
      StateCache.refresh_nm_state state
      StateCache.refresh_online state
    end
  end

  def refresh_setup_complete(status)
    @setup_complete = status
    ::System.push_status_update
  end

  def refresh_configured_at_boot(status)
    @configured_at_boot = status
    ::System.push_status_update
  end

  def refresh_online(nm_state)
    @online = System.state_is_online?(nm_state)
    ::System.push_status_update
  end

  def refresh_connectivity(status)
    @connectivity = status
    ::System.push_status_update
  end

  def refresh_conn_check_available(status)
    @connectivity_check_available = status
    ::System.push_status_update
  end

  # @param [Hash] status
  def refresh_network_status(status)
    @network_status = status
    ::System.push_status_update
  end

  def refresh_primary_connection(connection_info)
    @primary_connection = connection_info
    ::System.push_status_update
  end

  # @param [Object] ac_path
  # @return [nil]
  def schedule_pc_refresh(ac_path)
    if ac_path.eql?('/')
      refresh_primary_connection(nil)
    else
      # Use a delayed job to ensure the connection is already persisted with
      # its current active path.
      Rufus::Scheduler.singleton.in '10s' do
        model = NmNetwork.find_by(active_connection_path: ac_path)&.public_info
        StateCache.refresh_primary_connection(model)
      end
    end
  end

  def refresh_networks
    @networks = NmNetwork.all.map(&:public_info)
    ::System.push_status_update
  end

  def self.as_json
    hash = {}
    instance.instance_variables.map do |iv|
      hash[iv[1..-1].to_sym] = instance.instance_variable_get(iv)
    end
    hash
  end

  private

  def init_connectivity
    if OS.linux?
      NetworkManager::Commands.instance.connectivity
    else
      NetworkManager::Constants::NmConnectivityState::UNKNOWN
    end
  end

  def init_primary_connection
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
  end
end
