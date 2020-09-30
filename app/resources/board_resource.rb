# JSON representation of the Board model.
class BoardResource < JSONAPI::Resource
  attributes :title, :background_id, :background_url
  attribute :is_default

  has_many :widget_instances,
           always_include_linkage_data: true,
           exclude_links: [:self]
  has_many :rules,
           always_include_linkage_data: true,
           exclude_links: [:self]

  def is_default
    @model.default?
  end

  def background_id
    @model.background&.id
  end

  def background_url
    @model.background&.file_url
  end

  def background_id=(background_id)
    if background_id.blank?
      @model.background&.boards&.delete(id)
    else
      @model.background = Background.find(background_id)
    end
  end
end
