class WidgetResource < JSONAPI::Resource
  primary_key :slug
  key_type :string
  exclude_links [:self]

  attributes :name,
             :active,
             :title,
             :description,
             :sizes,
             :icon,
             :version,
             :compatibility,
             :single_source,
             :creator,
             :homepage,
             :download,
             :languages
  has_many :widget_instances,
           always_include_linkage_data: true,
           exclude_links: [:self]
  has_one :group,
          optional: true,
          exclude_links: [:self]
end
