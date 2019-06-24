  class NewsfeedResource < RecordableResource
    model_name 'GroupSchemas::Newsfeed'
    attributes :name, :url, :icon_url, :latest_entry, :items
    attribute :uid

    def items
      @model.items.sort_by(&:published).reverse.as_json(except: %i[newsfeed_id])
    end

    def uid
      @model.url
    end
  end
