class StateCache
  include ActiveModel::Validations

  attr_accessor :resetting, :connection_attempt, :setup_complete,
                :configured_at_boot, :current_ip, :online, :network_status
  validates :resetting, :connection_attempt, inclusion: [true, false]

  def initialize
    # FIXME: resetting is a temporary indicator, rework with https://gitlab.com/glancr/mirros_api/issues/87
    @resetting = false
    @connection_attempt = false
    @setup_complete = System.setup_completed?
    # FIXME: configured_at_boot is a temporary workaround to differentiate between
    # initial setup before first connection attempt and subsequent network problems.
    # Remove once https://gitlab.com/glancr/mirros_api/issues/87 lands
    @configured_at_boot = @setup_complete
    @current_ip = System.current_ip_address
    @online = System.online?
    @network_status = SettingExecution::Network.wifi_signal_status
  end

  def self.singleton
    @singleton ||= new
  end

  def self.s
    singleton
  end
end
