class WidgetInstanceResource < JSONAPI::Resource
  attributes :title, :showtitle, :configuration, :position
  has_one :widget, exclude_links: [:self]
  has_one :group, through: :widget, foreign_key_on: :widget, exclude_links: [:self]
  has_many :instance_associations, always_include_linkage_data: true, exclude_links: [:self]
  has_many :source_instances,
           through: :instance_associations,
           always_include_linkage_data: true,
           exclude_links: [:self]

  exclude_links :default
end
