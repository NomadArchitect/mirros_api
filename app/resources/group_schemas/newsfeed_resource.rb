# frozen_string_literal: true

class NewsfeedResource < RecordableResource
  model_name 'GroupSchemas::Newsfeed'
  attributes :name, :url, :icon_url, :latest_entry, :items
  key_type :string

  def items
    @model.items.sort_by(&:published).reverse.as_json
  end
  end
