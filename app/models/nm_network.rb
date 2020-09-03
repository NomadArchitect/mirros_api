# frozen_string_literal: true

require 'application_record' # @see config/initializers/scheduler.rb NmNetwork is required during boot

# Internal network metadata persistence for NetworkManager.
class NmNetwork < ApplicationRecord
  # Excludes the pre-defined LAN and setup WiFi connections by connection_id
  scope :user_defined, -> { where.not(connection_id: %w[glancrsetup glancrlan]) }
  scope :exclude_ap, -> { where.not(connection_id: 'glancrsetup') }
  scope :wifi, -> { where(interface_type: '802-11-wireless') }

  def deactivate(with_ip_check: true)
    attributes = { devices: nil, active: false, active_connection_path: nil }
    if with_ip_check
      settings = nm_settings
      attributes.merge!(
        ip4_address: settings.dig('ipv4', 'address-data', 0, 'address'),
        ip6_address: settings.dig('ipv6', 'address-data', 0, 'address')
      )
    end
    update(attributes)
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
