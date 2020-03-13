class AddReferenceToGroupSchemasCurrentWeatherEntries < ActiveRecord::Migration[5.2]
  def change
    add_reference :group_schemas_current_weather_entries,
                  :current_weather,
                  type: :string, index: { name: 'items_on_current_weather_id' }
  end
end
