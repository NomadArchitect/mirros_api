class AddSunsCourseToGroupSchemasWeatherOwm < ActiveRecord::Migration[5.2]
  def change
    add_column :group_schemas_weather_owms, :sunrise, :datetime
    add_column :group_schemas_weather_owms, :sunset, :datetime
  end
end
