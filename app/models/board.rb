class Board < ApplicationRecord
  before_destroy :abort_if_active
  has_many :widget_instances, dependent: :destroy

  def abort_if_active
    return unless id.eql?(SettingsCache.s[:system_activeboard].to_i)

    errors.add(:base, 'Cannot delete active board')
    throw(:abort)
  end
end
