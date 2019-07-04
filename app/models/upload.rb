class Upload < ApplicationRecord
  has_one_attached :file, dependent: :destroy

  def file_url
    return unless file.attached?

    Rails.application
      .routes
      .url_helpers
      .rails_blob_path(file, only_path: true)
  end

  def purge_and_destroy
    file.purge
    destroy
  end
end
