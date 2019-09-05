class Upload < ApplicationRecord
  has_one_attached :file, dependent: :destroy

  def file_url
    return unless file.attached?

    if file.image?
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
  end

  def purge_and_destroy
    file.purge
    destroy
  end
end
