class StateCache
  include ActiveModel::Validations

  attr_accessor :refresh_frontend, :resetting, :connection_attempt,
                :setup_complete, :configured_at_boot, :current_ip, :online, :network_status
  validates :refresh_frontend, :resetting, :connection_attempt, inclusion: [true, false]

  def initialize
    @refresh_frontend = true
    # FIXME: resetting is a temporary indicator, rework with https://gitlab.com/glancr/mirros_api/issues/87
    @resetting = false
    @connection_attempt = false
    @setup_complete = System.setup_completed?
    # configured_at_boot is set in the scheduler
    @configured_at_boot = false
    @current_ip = System.current_ip_address
    @online = System.online?
    @network_status = if SettingsCache.s[:network_connectiontype].eql?('wlan')
                        SettingExecution::Network.check_signal
                      end
  end

  def self.singleton
    @singleton ||= new
  end

  def self.s
    singleton
  end
end
