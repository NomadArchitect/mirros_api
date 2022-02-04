# frozen_string_literal: true

# Prevent scheduling for Rails console starts or rake tasks.
return unless Rails.const_defined? 'Server'

# FIXME: Ubuntu Core may loose timezone settings after reboot. Force a reset at startup.
# Remove once https://bugs.launchpad.net/snappy/+bug/1650688 is resolved.
System.reset_timezone if System.running_in_snap?

# Prime StateCache so everything has the latest values.
StateCache.refresh

# Determine if we need the AP right away
unless StateCache.get(:setup_complete) && NetworkManager::Bus.new.any_connectivity?
  SettingExecution::Network.open_ap
end
