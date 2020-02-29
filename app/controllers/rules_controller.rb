# frozen_string_literal: true

# Logic for board rules.
class RulesController < ApplicationController
  include JSONAPI::ActsAsResourceController

  def base_meta
    { system: RuleManager::SystemRulesProvider.rules }
  end
end
