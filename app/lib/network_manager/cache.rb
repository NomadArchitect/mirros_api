module NetworkManager
  class Cache
    include NetworkManager::Constants

    PUBLIC_KEYS = %i[
    state

    connectivity
    connectivity_check_available
    network_status
    primary_connection
    networks
  ].freeze

    def self.write(key, value)
      Rails.cache.write key, value, namespace: :network_status, expires_in: 60
    end

    def self.fetch(key)
      Rails.cache.fetch key, namespace: :network_status, expires_in: 60 do
        get_value key
      end
    end

    def self.store_network(id, uuid)
      Rails.cache.write id, uuid, namespace: :network_ids
    end

    def self.fetch_network(id)
      Rails.cache.fetch id, namespace: :network_ids do
        Bus.new.uuid_for_connection id
      end
    end

    def self.remove_all_networks
      Rails.cache.delete_matched '*', namespace: 'network_ids'
    end

    def self.get_value(key)
      bus = Bus.new
      case key
      when :state
        bus.state
      when :connectivity
        bus.connectivity
      when :network_status
        bus.wifi_status
      when :primary_connection
        bus.primary_connection
      else
        nil
      end
    end

    def self.as_json
      Rails
        .cache
        .fetch_multi(
          *PUBLIC_KEYS, namespace: :network)
    end
  end
end
