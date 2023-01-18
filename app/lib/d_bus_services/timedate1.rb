# frozen_string_literal: true

# Paths and macro for DBus connections to Linux' timedate1 service.
module DBusServices
  module Timedate1
    SERVICE = 'org.freedesktop.timedate1'
    OBJECT_PATH = '/org/freedesktop/timedate1'
    INTERFACE = 'org.freedesktop.timedate1'

    def self.instance
      DBus::ASystemBus.new[SERVICE][OBJECT_PATH][INTERFACE]
    end
  end
end
