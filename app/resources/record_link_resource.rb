# frozen_string_literal: true

class RecordLinkResource < JSONAPI::Resource
  immutable
  has_one :source_instance
  has_one :group
  has_one :recordable, polymorphic: true
end
