class SourceInstance < Instance
  belongs_to :source
  has_many :instance_associations, dependent: :destroy
  has_many :widget_instances, through: :instance_associations

  before_destroy :delete_records


  def get_records
    records = {}
    self.source.groups.map do |group|
      schema = group_schema(group)
      records[group.name] = schema.where(source_instance_id: self.id)
    end
    records
  end

  def delete_records
    self.source.groups.map do |group|
      schema = group_schema(group)
      schema.where(source_instance: self.id).delete_all
    end
  end

  private
    def group_schema(group)
      "#{self.source.id.capitalize}::#{group.name.capitalize}".safe_constantize
    end
end
