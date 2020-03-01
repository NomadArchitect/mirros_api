# frozen_string_literal: true

# JSON:API resource for Rule model.
class RuleResource < JSONAPI::Resource
  attributes :provider, :field, :operator, :value
  has_one :board,
          always_include_linkage_data: true,
          exclude_links: [:self]
  has_one :source_instance,
          always_include_linkage_data: true,
          exclude_links: [:self]
end
