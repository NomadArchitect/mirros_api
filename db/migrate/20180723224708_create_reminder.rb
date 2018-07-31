class CreateReminder < ActiveRecord::Migration[5.2]
  def change
    create_table :reminders do |t|
      t.string :type
      t.string :name
      t.string :description
      t.string :color
      t.references :source_instance, index: true, foreign_key: true
    end
  end
end
