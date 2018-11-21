class CreateGroupSchemasReminderItems < ActiveRecord::Migration[5.2]
  def change
    create_table :group_schemas_reminder_items, id: false do |t|
      t.string :uid, primary_key: true
      t.references :reminder_list
      t.datetime :dtstart
      t.string :summary
      t.string :description
    end
    add_index :group_schemas_reminder_items, :uid
  end
end
