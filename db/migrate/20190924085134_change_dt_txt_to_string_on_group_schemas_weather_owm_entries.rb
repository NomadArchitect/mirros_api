class ChangeDtTxtToStringOnGroupSchemasWeatherOwmEntries < ActiveRecord::Migration[5.2]
  def change
    change_column :group_schemas_weather_owm_entries, :dt_txt, :datetime
  end
end
