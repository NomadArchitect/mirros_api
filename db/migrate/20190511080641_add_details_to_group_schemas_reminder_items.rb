class AddDetailsToGroupSchemasReminderItems < ActiveRecord::Migration[5.2]
  def change
    rename_column :group_schemas_reminder_items, :dtstart, :due_date
    add_column :group_schemas_reminder_items, :completed, :boolean
    add_column :group_schemas_reminder_items, :creation_date, :datetime
    add_column :group_schemas_reminder_items, :assignee, :string
  end
end
