class StatusChannel < ApplicationCable::Channel
  def subscribed
    stream_from 'status'
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end
end
