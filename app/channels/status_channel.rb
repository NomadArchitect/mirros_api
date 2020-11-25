# frozen_string_literal: true

class StatusChannel < ApplicationCable::Channel
  def subscribed
    stream_from 'status'
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end

  # @param [Object] data A hash containing fields `orientation`, `width` and `height`.
  # @return [ActiveModel]
  def client_display(data)
    SystemState
      .find_or_initialize_by(variable: 'client_display')
      .update(
        value: {
          orientation: data['orientation'] || 'portrait',
          width: data['width'] || 1080,
          height: data['height'] || 1920
        }
      )
  end
end
