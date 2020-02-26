# frozen_string_literal: true

class UpdatesChannel < ApplicationCable::Channel
  def subscribed
    stream_from 'updates'
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end
end
