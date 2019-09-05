# frozen_string_literal: true

# Base class for all mirr.OS AR models.
class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true
  after_commit :broadcast, if: :broadcastable?

  def broadcastable?
    [
      Widget,
      WidgetInstance,
      Source,
      SourceInstance,
      InstanceAssociation,
      Setting
    ].include? self.class
  end

  def broadcast
    ActionCable.server.broadcast 'updates',
                                 payload: serialize_resource,
                                 type: destroyed? ? 'deletion' : 'update'
  rescue StandardError => e
    Rails.logger.error "Failed to broadcast #{self.class} #{id} update: #{e.message}"
  end

  def serialize_resource
    res_class = "#{self.class}Resource".safe_constantize
    raise ArgumentError, "Could not constantize #{self.class}Resource" if res_class.nil?

    # Unless we're broadcasting a destroyed model:
    # Reload from DB to ensure we're not pushing stale data, see https://github.com/rails/rails/issues/27342
    res = res_class.new(destroyed? ? self : reload, nil)
    includes = case res # Use instance here since case evaluates the class
               when SourceInstanceResource
                 %w[source widget_instances instance_associations]
               when WidgetInstanceResource
                 %w[widget source_instances instance_associations]
               when InstanceAssociationResource
                 %w[source_instance widget_instance]
               else
                 []
               end
    JSONAPI::ResourceSerializer.new(res_class, include: includes).serialize_to_hash(res)
  end
end
