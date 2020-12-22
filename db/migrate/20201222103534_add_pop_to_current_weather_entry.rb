class AddPopToCurrentWeatherEntry < ActiveRecord::Migration[5.2]
  def change
    add_column :current_weather_entries, :pop, :decimal
  end
end
