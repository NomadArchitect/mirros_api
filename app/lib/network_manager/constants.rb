# frozen_string_literal: true

module NetworkManager
  module Constants
    # Helpers for reused String values
    module NmInterfaces
      ACCESS_POINT = 'org.freedesktop.NetworkManager.AccessPoint'
      CONNECTION_ACTIVE = 'org.freedesktop.NetworkManager.Connection.Active'
      DEVICE = 'org.freedesktop.NetworkManager.Device'
      DEVICE_WIRELESS = 'org.freedesktop.NetworkManager.Device.Wireless'
      SETTINGS = 'org.freedesktop.NetworkManager.Settings'
      SETTINGS_CONNECTION = 'org.freedesktop.NetworkManager.Settings.Connection'
      IP4CONFIG = 'org.freedesktop.NetworkManager.IP4Config'
    end

    # NetworkManager DBus API Type constants.
    # See https://developer.gnome.org/NetworkManager/1.2/nm-dbus-types.html

    # NmState values indicate the current overall networking state.
    module NmState
      # networking state is unknown
      UNKNOWN = 0
      # networking is not enabled
      ASLEEP = 10
      # there is no active network connection
      DISCONNECTED = 20
      # network connections are being cleaned
      DISCONNECTING = 30
      # a network connection is being started
      CONNECTING = 40
      # there is only local IPv4 and/or IPv6 connectivity
      CONNECTED_LOCAL = 50
      # there is only site-wide IPv4 and/or IPv6 connectivity
      CONNECTED_SITE = 60
      # there is global IPv4 and/or IPv6 Internet connectivity
      CONNECTED_GLOBAL = 70
    end

    # NMActiveConnectionState values indicate the state of a connection to a specific network while it is starting, connected, or disconnecting from that network.
    module NmActiveConnectionState
      # the state of the connection is unknown
      UNKNOWN = 0
      # a network connection is being prepared
      ACTIVATING = 1
      # there is a connection to the network
      ACTIVATED = 2
      # the network connection is being torn down and cleaned up
      DEACTIVATING = 3
      # the network connection is disconnected and will be removed
      DEACTIVATED = 4
    end

    module NmDeviceType
      UNKNOWN = 0
      # unknown device
      ETHERNET = 1
      # a wired ethernet device
      WIFI = 2
      # an 802.11 WiFi device
      UNUSED1 = 3
      # not used
      UNUSED2 = 4
      # not used
      BT = 5
      # a Bluetooth device supporting PAN or DUN access protocols
      OLPC_MESH = 6
      # an OLPC XO mesh networking device
      WIMAX = 7
      # an 802.16e Mobile WiMAX broadband device
      MODEM = 8
      # a modem supporting analog telephone, CDMA/EVDO, GSM/UMTS, or LTE network access protocols
      INFINIBAND = 9
      # an IP-over-InfiniBand device
      BOND = 10
      # a bond master interface
      VLAN = 11
      # an 802.1Q VLAN interface
      ADSL = 12
      # ADSL modem
      BRIDGE = 13
      # a bridge master interface
      GENERIC = 14
      # generic support for unrecognized device types
      TEAM = 15
      # a team master interface
      TUN = 16
      # a TUN or TAP interface
      IP_TUNNEL = 17
      # a IP tunnel interface
      MACVLAN = 18
      # a MACVLAN interface
      VXLAN = 19
      # a VXLAN interface
      VETH = 20
      # a VETH interface
    end

    module NMDeviceState
      UNKNOWN = 0
      # the device's state is unknown
      UNMANAGED = 10
      # the device is recognized, but not managed by NetworkManager
      UNAVAILABLE = 20
      # the device is managed by NetworkManager, but is not available for use. Reasons may include the wireless switched off, missing firmware, no ethernet carrier, missing supplicant or modem manager, etc.
      DISCONNECTED = 30
      # the device can be activated, but is currently idle and not connected to a network.
      PREPARE = 40
      # the device is preparing the connection to the network. This may include operations like changing the MAC address, setting physical link properties, and anything else required to connect to the requested network.
      CONFIG = 50
      # the device is connecting to the requested network. This may include operations like associating with the WiFi AP, dialing the modem, connecting to the remote Bluetooth device, etc.
      NEED_AUTH = 60
      # the device requires more information to continue connecting to the requested network. This includes secrets like WiFi passphrases, login passwords, PIN codes, etc.
      IP_CONFIG = 70
      # the device is requesting IPv4 and/or IPv6 addresses and routing information from the network.
      IP_CHECK = 80
      # the device is checking whether further action is required for the requested network connection. This may include checking whether only local network access is available, whether a captive portal is blocking access to the Internet, etc.
      SECONDARIES = 90
      # the device is waiting for a secondary connection (like a VPN) which must activated before # the device can be activated
      ACTIVATED = 100
      # the device has a network connection, either local or global.
      DEACTIVATING = 110
      # a disconnection from the current network connection was requested, and # the device is cleaning up resources used for that connection. The network connection may still be valid.
      FAILED = 120
      # the device failed to connect to the requested network and is cleaning up the connection request
    end

    module NmConnectivityState
      # Network connectivity is unknown.
      UNKNOWN = 1
      # The host is not connected to any network.
      NONE = 2
      # The host is behind a captive portal and cannot reach the full Internet.
      PORTAL = 3
      # The host is connected to a network, but does not appear to be able to reach the full Internet.
      LIMITED = 4
      # The host is connected to a network, and appears to be able to reach the full Internet.
      FULL = 5
    end
  end
end
