class CreateGroupSchemasPublicTransports < ActiveRecord::Migration[5.2]
  def change
    create_table :group_schemas_public_transports do |t|
      t.string :uuid, null: false
      t.string :type
      t.datetime :departure, null: false
      t.integer :delay_minutes
      t.string :line, null: false
      t.string :direction, null: false
      t.string :transit_type
      t.string :platform
    end
    add_index :group_schemas_public_transports, :uuid, unique: true
  end
end
