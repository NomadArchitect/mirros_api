# frozen_string_literal: true

require 'network_manager/logger'
require 'active_support/tagged_logging'

NetworkManager::Logger.logger = ActiveSupport::TaggedLogging.new(
  NetworkManager::Logger.new('log/network.log', 0, 5.megabytes)
)
