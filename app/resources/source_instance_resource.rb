class SourceInstanceResource < JSONAPI::Resource
  attributes :title, :configuration, :options, :last_refresh, :refresh_interval, :records

  has_one :source, exclude_links: [:self]
  has_many :widget_instances,
           through: :instance_associations,
           always_include_linkage_data: true,
           exclude_links: [:self]

  def records
    records = {}
    @model.record_links.map do |link|
      group_id = link.group.id
      records[group_id] ||= {}
      resource_type = "#{group_id.classify}Resource".safe_constantize
      recordable = link.recordable
      serialized = JSONAPI::ResourceSerializer.new(
        resource_type, key_formatter: JSONAPI::KeyFormatter
      ).serialize_to_hash(
        resource_type.new(recordable, nil)
      )
      records[group_id][recordable.id] = serialized[:data]

    end
    records
  end

end
