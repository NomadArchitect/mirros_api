class AddPopToCurrentWeatherEntries < ActiveRecord::Migration[5.2]
  def change
    add_column :group_schemas_current_weather_entries,
               :pop,
               :decimal,
               { precision: 3, scale: 2 }
  end
end
