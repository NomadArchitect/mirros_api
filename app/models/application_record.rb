class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true
  after_save :broadcast
  after_destroy :broadcast

  def broadcast
    res_class = "#{self.class}Resource".safe_constantize
    return if res_class.nil?
    return unless [SourceInstanceResource, WidgetInstanceResource, InstanceAssociationResource].include? res_class

    res = res_class.new(self, nil)
    includes = case res
               when SourceInstanceResource
                 %w[source widget_instances instance_associations record_links record_links.recordable]
               when WidgetInstanceResource
                 %w[widget source_instances instance_associations]
               when InstanceAssociationResource
                 %w[source_instance widget_instance source_instance.record_links source_instance.record_links.recordable]
               else
                 []
               end

    serialized_res = JSONAPI::ResourceSerializer.new(res_class, include: includes).serialize_to_hash(res)
    ActionCable.server.broadcast 'updates',
                                 payload: serialized_res,
                                 type: destroyed? ? 'deletion' : 'update'
  end
end
