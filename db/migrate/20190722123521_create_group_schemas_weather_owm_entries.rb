class CreateGroupSchemasWeatherOwmEntries < ActiveRecord::Migration[5.2]
  def change
    create_table :group_schemas_weather_owm_entries, id: false do |t|
      t.references :weather_owm, type: :string
      t.timestamp :dt_txt
      t.json :forecast
      t.string :unit
      t.timestamps
    end
  end
end
