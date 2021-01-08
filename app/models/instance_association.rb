# frozen_string_literal: true

# Intermediary model for 1-1 associations between a WidgetInstance and a SourceInstance.
class InstanceAssociation < ApplicationRecord
  belongs_to :group
  belongs_to :widget_instance
  belongs_to :source_instance

  after_commit :fetch_data, on: %i[create update]

  def fetch_data
    source_instance.update_data(group_id: group_id, sub_resources: configuration['chosen'])
  rescue ArgumentError => e
    Rails.logger.warn error_with_backtrace e
  rescue StandardError => e
    Rails.logger.error "Initial data fetch of #{source_instance.source} instance #{source_instance}:
            #{error_with_backtrace e}"
    raise e
  end

  private

  # Returns an error message along with the first three backtrace lines.
  # @param [StandardError] error
  def error_with_backtrace(error)
    "#{error.message}\n #{error.backtrace[0, 3]&.join("\n")}"
  end
end
