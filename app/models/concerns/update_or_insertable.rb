# frozen_string_literal: true

require 'active_support/concern'

# Concern to enable in-place update-or-insert operations on associated models.
module UpdateOrInsertable
  extend ActiveSupport::Concern

  included do
    def update_or_insert_child(id, values = {})
      assoc = self.class::UPSERT_ASSOC
      id_field = self.class::ID_FIELD || :uid
      child = send(assoc).find_or_initialize_by(id_field => id)
      association(assoc).add_to_target(child)
      child.attributes = values
    end
  end
end
