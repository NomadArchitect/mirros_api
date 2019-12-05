# frozen_string_literal: true

# In-memory cache for application state
class StateCache
  include ActiveModel::Validations
  include Singleton

  attr_accessor :resetting, :connection_attempt, :setup_complete,
                :configured_at_boot, :online, :primary_connection,
                :connectivity, :connectivity_check_available, :network_status
  validates :resetting, :connection_attempt, inclusion: [true, false]

  class << self
    delegate_missing_to :instance
  end

  # FIXME: Maybe there's a nicer way to ensure instant Websocket updates on
  # every StateCache write access?

  # Add a generic handler that fires a websocket update every time the
  # StateCache is updated. Other methods with metaprogramming are fragile for
  # methods with parameters. Regex excludes initializer methods (would create
  # infinite loops) and attr_reader methods to avoid spamming clients.
  TracePoint.trace(:call) do |tp|
    if tp.defined_class.eql?(StateCache) && !tp.method_id.match?(/^init|=$/)
      ::System.push_status_update
    end
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
    @connectivity_check_available = NetworkManager::Commands.instance.connectivity_check_available?
    @connectivity = init_connectivity
    @network_status = SettingExecution::Network.wifi_signal_status

    # private
    @primary_connection = init_primary_connection
    @networks = NmNetwork.all.map(&:public_info)
  end
  def refresh_networks
    @networks = NmNetwork.all.map(&:public_info)
  end

  # @param [Object] ac_path
  # @return [nil]
  def update_primary_connection(ac_path)
    if ac_path.eql?('/')
      @primary_connection = nil
    else
      # Use a delayed job to ensure the connection is already persisted with
      # its current active path.
      Rufus::Scheduler.singleton.in '10s' do
        @primary_connection = NmNetwork.find_by(
          active_connection_path: ac_path
        )&.public_info
      end
    end
  end

  def update_online_status(nm_state)
    @online = System.state_is_online?(nm_state)
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
