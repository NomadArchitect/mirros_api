class Upload < ApplicationRecord
  has_one_attached :file, dependent: :destroy

  def file_url
    return unless file.attached?

    obj = if file.image?
            file.variant(resize: '1920x1920').processed
          else
            file
          end
    Rails.application.routes.url_helpers.rails_representation_url(
      obj,
      host: ActiveStorage::Current.host
    )

  end

  def purge_and_destroy
    file.purge
    destroy
  end
end
