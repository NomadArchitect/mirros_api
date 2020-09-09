# frozen_string_literal: true

class GroupResource < JSONAPI::Resource
  primary_key :slug
  key_type :string

  attributes :name
  has_many :widgets, always_include_linkage_data: true, exclude_links: [:self]
  has_many :data_sources, always_include_linkage_data: true, exclude_links: [:self]
end
