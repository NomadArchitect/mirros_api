# frozen_string_literal: true

class Upload < ApplicationRecord
  has_one_attached :file, dependent: :destroy

  delegate :content_type, to: :file

  # Checks if the attached file is an image (excluding SVG).
  # @return [TrueClass, FalseClass] True if file is a raster graphics image
  def attached_file_is_image?
    file.image? && !file.content_type.include?('svg')
  end

  # Generates the URL to the processed variant representation for the attached file.
  # @return [String] The complete URL to the file attachment
  def file_url
    return unless file.attached?

    if attached_file_is_image?
      Rails.application.routes.url_helpers.rails_representation_url(
        file.variant(resize: '1920x1920').processed,
        host: ActiveStorage::Current.host
      )
    else
      Rails.application.routes.url_helpers.rails_blob_url(
        file,
        host: ActiveStorage::Current.host
      )
    end
  rescue SystemCallError => e
    Rails.logger.warn "#{__method__}: #{e.message}"
    ''
  end

  def purge_and_destroy
    file.purge
    destroy
  end
end
