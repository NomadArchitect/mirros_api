# frozen_string_literal: true

NetworkManager::Logger.logger = ActiveSupport::TaggedLogging.new(
  NetworkManager::Logger.new('log/network.log', 0, 5.megabytes)
)
