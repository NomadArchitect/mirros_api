class InstanceAssociation < ApplicationRecord
  belongs_to :group
  belongs_to :widget_instance
  belongs_to :source_instance

  after_create :fetch_data

  def fetch_data
    source_instance = self.source_instance
    source = source_instance.source

    if source_instance.configuration.empty?
      Rails.logger.info "Configuration for instance #{source_instance.id} of #{source.name} is empty, aborting initial fetch."
      return
    end

    source_hooks = "#{source.name.camelcase}::Hooks".safe_constantize
    if source_hooks.nil?
      Rails.logger.error "Could not instantiate hooks class of engine #{source.name}"
      return
    end


    sub_resources = configuration['chosen']
    source_hooks_instance = source_hooks.new(source_instance.id,
                                             source_instance.configuration)

    recordables = source_hooks_instance.fetch_data(group_id, sub_resources)
    recordables.each do |recordable|
      recordable.save
      next unless recordable.record_link.nil?

      source_instance.record_links <<
        RecordLink.create(recordable: recordable, group_id: group)
      source_instance.save
    end
  rescue => e
    Rails.logger.error e.message

    source_instance.update(last_refresh: Date.new)
  end
end
