# frozen_string_literal: true

# Internal network metadata persistence for NetworkManager.
class NmNetwork < ApplicationRecord
  # Excludes the pre-defined LAN and setup WiFi connections by connection_id
  scope :user_defined, -> { where.not(connection_id: %w[glancrsetup glancrlan]) }
  scope :wifi, -> { where(interface_type: '802-11-wireless') }
end
