# frozen_string_literal: true

# In-memory cache for application state
class StateCache
  include ActiveModel::Validations
  include Singleton

  attr_accessor :resetting, :connection_attempt, :setup_complete,
                :configured_at_boot, :online, :connectivity,
                :network_status
  validates :resetting, :connection_attempt, inclusion: [true, false]

  class << self
    delegate_missing_to :instance
  end

  def initialize
    # FIXME: resetting is a temporary indicator, rework with https://gitlab.com/glancr/mirros_api/issues/87
    @resetting = false
    @connection_attempt = false
    @setup_complete = System.setup_completed?
    # FIXME: configured_at_boot is a temporary workaround to differentiate between
    # initial setup before first connection attempt and subsequent network problems.
    # Remove once https://gitlab.com/glancr/mirros_api/issues/87 lands
    @configured_at_boot = @setup_complete
    @online = System.online?
    @connectivity = initial_connectivity
    @network_status = SettingExecution::Network.wifi_signal_status

    # private
    primary_path = if OS.linux?
                     NetworkManager::Commands.instance.primary_connection
                   else
                     '/'
                   end
    @primary_connection = update_primary_connection(primary_path)
    @networks = NmNetwork.all.map(&:public_info)
  end

  def refresh_networks
    @networks = NmNetwork.all.map(&:public_info)
  end

  def update_primary_connection(ac_path)
    @primary_connection = NmNetwork.find_by(
      active_connection_path: ac_path
    )&.public_info
  end

  def self.as_json
    hash = {}
    instance.instance_variables.map do |iv|
      hash[iv[1..-1].to_sym] = instance.instance_variable_get(iv)
    end
    hash
  end

  private

  def initial_connectivity
    if OS.linux?
      NetworkManager::Commands.instance.connectivity
    else
      NetworkManager::Constants::NmConnectivityState::UNKNOWN
    end
  end
end
