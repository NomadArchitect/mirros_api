# frozen_string_literal: true

class StatusChannel < ApplicationCable::Channel
  def subscribed
    stream_from 'status'
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end

  # Stores display layout from a connected client.
  # @param [Object] data Display layout configuration
  # @option data [String] :orientation The screen orientation, one of [portrait, landscape]. Defaults to `portrait`.
  # @option data [Integer] :width The client's window width. Defaults to 1080.
  # @option data [Integer] :height The client's window height. Defaults to 1920.
  # @return [ActiveModel] The created or updated model.
  def client_display(data)
    EnvironmentVariable
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
