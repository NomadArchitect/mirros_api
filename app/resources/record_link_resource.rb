# frozen_string_literal: true

class RecordLinkResource < JSONAPI::Resource
  immutable
  has_one :source_instance, exclude_links: :default
  has_one :group, exclude_links: :default
  has_one :recordable, polymorphic: true, exclude_links: :default
end
