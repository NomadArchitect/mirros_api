# frozen_string_literal: true

class CreateGroupSchemasPublicTransports < ActiveRecord::Migration[5.2]
  def change
    create_table :group_schemas_public_transports, id: false do |t|
      t.string :id, primary_key: true
      t.string :type
      t.string :station_name
      t.timestamps
    end
  end
end
