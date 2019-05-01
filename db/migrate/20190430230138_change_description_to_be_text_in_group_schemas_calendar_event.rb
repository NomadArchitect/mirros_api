class ChangeDescriptionToBeTextInGroupSchemasCalendarEvent < ActiveRecord::Migration[5.2]
  def change
    change_column :group_schemas_calendar_events, :description, :text
  end
end
