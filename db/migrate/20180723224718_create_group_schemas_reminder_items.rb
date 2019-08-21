class CreateGroupSchemasReminderItems < ActiveRecord::Migration[5.2]
  def change
    create_table :group_schemas_reminder_items, id: false do |t|
      t.string :uid, primary_key: true
      t.references :reminder_list, type: :string
      t.datetime :due_date
      t.datetime :creation_date
      t.boolean :completed
      t.string :summary
      t.string :description
      t.string :assignee
      t.timestamps
    end
  end
end
