class Board < ApplicationRecord
  before_destroy :abort_if_active
  has_many :widget_instances, dependent: :destroy
  has_many :rules, dependent: :destroy
  belongs_to :background, # background may be re-used across boards.
             foreign_key: :uploads_id, # use a single table for uploads.
             inverse_of: :boards,
             optional: true # background image is optional.

  def abort_if_active
    return unless id.eql?(SettingsCache.s[:system_activeboard].to_i)

    errors.add(:base, 'Cannot delete active board')
    throw(:abort)
  end
end
