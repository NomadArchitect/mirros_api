# frozen_string_literal: true

class CreateGroupSchemasCurrentWeatherEntries < ActiveRecord::Migration[5.2]
  def change
    create_table :group_schemas_current_weather_entries, id: false do |t|
      t.string :uid, primary_key: true
      t.float :temperature
      t.integer :humidity
      t.float :wind_speed
      t.integer :wind_angle
      t.float :air_pressure
      t.integer :rain_last_hour
      t.string :condition_code
      t.timestamps
    end
  end
end
