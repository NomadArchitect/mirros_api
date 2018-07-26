class SourceInstance < Instance
  belongs_to :source
  has_many :instance_associations, dependent: :destroy
  has_many :widget_instances, through: :instance_associations
  def get_records
    records = {}
    self.source.groups.map do |group|
      schema = group_schema(group)
      records[group.name] = schema.where(source_instance: self.id)
    end
    records
  end
  private
    def group_schema(group)
      "#{self.source.id.capitalize}::#{group.name.capitalize}".safe_constantize
    end
end
