# This migration comes from openweathermap (originally 20181106083050)
class CreateOpenweathermapCities < ActiveRecord::Migration[5.2]
  def change
    create_table :openweathermap_cities, id: false do |t|
      t.primary_key :id
      t.string :name
      t.string :country
    end

    add_index :openweathermap_cities, :name
  end
end
