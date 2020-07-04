# frozen_string_literal: true

# Controller for Board resources.
class BoardsController < ApplicationController
  include JSONAPI::ActsAsResourceController

  # Enables background image URL generation. @see UploadsController
  # FIXME: Evaluate if this should be on ApplicationController or even static.
  before_action do
    ActiveStorage::Current.host = request.base_url
  end
end
