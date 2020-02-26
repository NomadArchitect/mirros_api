# frozen_string_literal: true

class InstanceAssociation < ApplicationRecord
  belongs_to :group
  belongs_to :widget_instance
  belongs_to :source_instance

  after_commit :fetch_data, on: %i[create update]

  def fetch_data
    source_instance = self.source_instance
    source = source_instance.source

    if source_instance.configuration.empty?
      Rails.logger.info "Configuration for instance #{source_instance.id} of #{source.name} is empty, aborting initial fetch."
      return
    end

    source_hooks = "#{source.name.camelize}::Hooks".safe_constantize
    if source_hooks.nil?
      Rails.logger.error "Could not instantiate hooks class of engine #{source.name}"
      return
    end

    sub_resources = configuration['chosen']
    source_hooks_instance = source_hooks.new(source_instance.id,
                                             source_instance.configuration)

    ActiveRecord::Base.transaction do
      begin
        recordables = source_hooks_instance.fetch_data(group_id, sub_resources)
      rescue StandardError => e
        Rails.logger.error "Error during initial data fetch of #{source} instance #{source_instance.id}: #{e.message}"
        return
      end

      recordables.each do |recordable|
        recordable.save!
        next unless recordable.record_link.nil?

        source_instance.record_links <<
          RecordLink.new(recordable: recordable, group: Group.find(group_id))
      end
      source_instance.save
      source_instance.update(last_refresh: Time.now.utc)
    end
  end
end
