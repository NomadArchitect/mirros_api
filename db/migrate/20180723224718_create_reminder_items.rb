class CreateReminderItems < ActiveRecord::Migration[5.2]
  def change
    create_table :reminder_items do |t|
      t.references :reminder_list
      t.datetime :dtstart
      t.string :summary
      t.string :description
    end
  end
end
