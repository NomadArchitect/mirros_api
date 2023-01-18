# Attempts to set the correct system time via timedate1 DBus.
class ChangeSystemTimeJob < ApplicationJob
  queue_as :system

  def perform(epoch_timestamp)
    return if OS.mac? && Rails.env.development? # Bail in macOS dev env.
    raise NotImplementedError, 'timedate control only implemented for Linux hosts' unless OS.linux?
    unless epoch_timestamp.instance_of?(Integer)
      raise ArgumentError, "not an integer: #{epoch_timestamp}"
    end

    timedated_interface = DBusServices::Timedate1.instance
    # noinspection RubyResolve
    timedated_interface.SetNTP(false, false) # Disable NTP to allow setting the time
    # wait half a second to ensure DBus is not busy anymore.
    sleep 0.5
    # noinspection RubyResolve
    timedated_interface.SetTime(epoch_timestamp * 1_000_000, false, false) # timedated requires microseconds
    # wait to ensure DBus is not busy anymore.
    sleep 1
    # noinspection RubyResolve
    timedated_interface.SetNTP(true, false) # Re-enable NTP
  end
end
