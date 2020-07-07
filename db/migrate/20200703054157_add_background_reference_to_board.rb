class AddBackgroundReferenceToBoard < ActiveRecord::Migration[5.2]
  def change
    add_reference :boards, :uploads, foreign_key: true
  end
end
