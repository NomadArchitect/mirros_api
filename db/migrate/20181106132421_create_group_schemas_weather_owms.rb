class CreateGroupSchemasWeatherOwms < ActiveRecord::Migration[5.2]
  def change
    create_table :group_schemas_weather_owms, id: false do |t|
      t.string :id, primary_key: true
      t.string :type
      t.string :location_name
    end
  end
end
