class CreateGroupSchemasWeatherOwms < ActiveRecord::Migration[5.2]
  def change
    create_table :group_schemas_weather_owms do |t|
      t.string :type
      t.timestamp :dt_txt
      t.json :forecast
      t.string :unit

      t.timestamps
    end
  end
end
