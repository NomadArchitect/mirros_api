# frozen_string_literal: true

# FIXME: Temporary workaround until https://bugs.launchpad.net/snapd/+bug/1851480 is fixed
if OS.linux? && Rails.const_defined?('Server')
  NetworkManager::Commands.instance.sync_all_connections
end
