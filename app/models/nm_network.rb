# frozen_string_literal: true

# Internal network metadata persistence for NetworkManager.
class NmNetwork < ApplicationRecord
  # Excludes the pre-defined LAN and setup WiFi connections by connection_id
  scope :user_defined, -> { where.not(connection_id: %w[glancrsetup glancrlan]) }
  scope :wifi, -> { where(interface_type: '802-11-wireless') }

  def deactivate
    settings = nm_settings
    update(
      devices: nil,
      active: false,
      active_connection_path: nil,
      ip4_address: settings.dig('ipv4', 'address-data', 0, 'address'),
      ip6_address: settings.dig('ipv6', 'address-data', 0, 'address')
    )
  end

  def update_static_ip_settings
    settings = nm_settings
    update(
      ip4_address: settings.dig('ipv4', 'address-data', 0, 'address'),
      ip6_address: settings.dig('ipv6', 'address-data', 0, 'address')
    )
  end

  def public_info
    as_json(
      except: %i[
        uuid
        devices
        active_connection_path
        connection_settings_path
        created_at
        updated_at
      ]
    )
  end

  private

  def nm_settings
    NetworkManager::Commands.instance.settings_for_connection_path(
      connection_path: connection_settings_path
    )
  end
end
