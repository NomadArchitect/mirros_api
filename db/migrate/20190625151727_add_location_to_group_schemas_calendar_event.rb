class AddLocationToGroupSchemasCalendarEvent < ActiveRecord::Migration[5.2]
  def change
    add_column :group_schemas_calendar_events, :location, :string
  end
end
