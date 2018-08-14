class CreateReminderLists < ActiveRecord::Migration[5.2]
  def change
    create_table :reminder_lists do |t|
      t.string :uid
      t.string :type
      t.string :name
      t.string :description
      t.string :color
    end
  end
end
