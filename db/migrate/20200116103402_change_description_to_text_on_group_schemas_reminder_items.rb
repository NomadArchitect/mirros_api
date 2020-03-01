# frozen_string_literal: true

class ChangeDescriptionToTextOnGroupSchemasReminderItems < ActiveRecord::Migration[5.2]
  def change
    change_column :group_schemas_reminder_items, :description, :text
  end
end
