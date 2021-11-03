class RefreshSourceInstanceJob < ApplicationJob
  queue_as :sources

  # @param [Integer] source_instance_id
  def perform(source_instance_id)
    unless System.online?
      Rails.logger.info("Skipped #{self.class} #{job_id} for SourceInstance #{source_instance_id}: System offline")
      return
    end

    source_instance = SourceInstance.find source_instance_id
    source_instance.refresh
  end
end
