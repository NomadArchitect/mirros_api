# frozen_string_literal: true

# FIXME: Temporary workaround until https://bugs.launchpad.net/snapd/+bug/1851480 is fixed
if OS.linux? && Rails.const_defined?('Server')
  # Synchronize NM connections to new NmNetwork model if required.
  networks = %w[glancrsetup glancrlan]
  ssid = Setting.find_by(slug: 'network_ssid')
  networks.append(ssid.value) if ssid.value.present?
  networks.each do |network_name|
    next if NmNetwork.find_by(connection_id: network_name).present?

    NetworkManager::Commands.instance.sync_db_to_nm_connection(
      connection_id: network_name
    )
  end
end
