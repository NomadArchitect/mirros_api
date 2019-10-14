# frozen_string_literal: true

# Internal network metadata persistence for NetworkManager.
class NmNetwork < ApplicationRecord
  scope :user_defined, -> { where.not(connection_id: %w[glancrsetup glancrlan]) }
  scope :wifi, -> { where(interface_type: '802-11-wireless') }
end
