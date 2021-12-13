# frozen_string_literal: true

# Internal network metadata persistence for NetworkManager.
class NmNetwork
  include ActiveModel::AttributeMethods
  include ActiveModel::Serializers::JSON

  define_attribute_methods :id,
                           :uuid,
                           :interface_type,
                           :active_connection_path
  attr_accessor :id,
                :uuid,
                :interface_type,
                :active_connection_path

  # TODO: Refactor as filter methods since we can't use scopes here
  # Excludes the pre-defined LAN and setup Wifi connections by connection_id
  #scope :user_defined, -> { where.not(connection_id: %w[glancrsetup glancrlan]) }
  #scope :exclude_ap, -> { where.not(connection_id: 'glancrsetup') }
  #scope :wifi, -> { where(interface_type: '802-11-wireless') }

  # @see https://developer-old.gnome.org/NetworkManager/stable/gdbus-org.freedesktop.NetworkManager.Connection.Active.html#gdbus-property-org-freedesktop-NetworkManager-Connection-Active.Connection Available properties
  # @param [Hash] attributes
  # @param [String] ip4_address
  def initialize(attributes, ip4_address, ip6_address, object_path)
    @id = attributes['Id']
    @uuid = attributes['Uuid']
    @interface_type = attributes['Type']
    @ip4_address = ip4_address
    @ip6_address = ip6_address
    @active_connection_path = object_path
  end

  def attributes
    {
      'id': nil,
      'uuid': nil,
      'interface_type': nil,
      'ip4_address': nil,
      'ip6_address': nil
    }
  end
end
