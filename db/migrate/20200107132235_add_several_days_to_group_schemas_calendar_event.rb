class AddSeveralDaysToGroupSchemasCalendarEvent < ActiveRecord::Migration[5.2]
  def change
    add_column :group_schemas_calendar_events,  :several_days, :boolean, default: false
  end
end
