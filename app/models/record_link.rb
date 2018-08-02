class RecordLink < ApplicationRecord
  belongs_to :recordable, polymorphic: true, dependent: :destroy
  belongs_to :group
  belongs_to :source_instance

  def recordable_type=(s_type)
    super(s_type.to_s.classify.constantize.base_class.to_s)
  end
end
