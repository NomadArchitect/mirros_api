# frozen_string_literal: true

class CreateGroupSchemasCurrentWeathers < ActiveRecord::Migration[5.2]
  def change
    create_table :group_schemas_current_weathers, id: false do |t|
      t.string :id, primary_key: true
      t.string :type
      t.string :station_name
      t.string :location
      t.timestamps
    end
  end
end
