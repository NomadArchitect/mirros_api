class DropOpenweathermapCities < ActiveRecord::Migration[5.2]
  def change
    drop_table(:openweathermap_cities) if table_exists?(:openweathermap_cities)
  end
end
