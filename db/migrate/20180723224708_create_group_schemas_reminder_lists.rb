class CreateGroupSchemasReminderLists < ActiveRecord::Migration[5.2]
  def change
    create_table :group_schemas_reminder_lists do |t|
      t.string :uid
      t.string :type
      t.string :name
      t.string :description
      t.string :color

      t.timestamps
    end
    add_index :group_schemas_reminder_lists, :uid
  end
end
