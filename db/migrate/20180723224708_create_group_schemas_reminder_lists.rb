# frozen_string_literal: true

class CreateGroupSchemasReminderLists < ActiveRecord::Migration[5.2]
  def change
    create_table :group_schemas_reminder_lists, id: false do |t|
      t.string :id, primary_key: true
      t.string :type
      t.string :name
      t.string :description
      t.string :color
      t.timestamps
    end
    add_index :group_schemas_reminder_lists, :id
  end
end
