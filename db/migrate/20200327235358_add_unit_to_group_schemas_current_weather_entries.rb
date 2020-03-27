class AddUnitToGroupSchemasCurrentWeatherEntries < ActiveRecord::Migration[5.2]
  def change
    add_column :group_schemas_current_weather_entries, :unit, :string
  end
end
