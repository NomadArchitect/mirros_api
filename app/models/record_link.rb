# frozen_string_literal: true

class RecordLink < ApplicationRecord
  belongs_to :recordable,
             polymorphic: true,
             dependent: :destroy
  belongs_to :group
  belongs_to :source_instance
end
