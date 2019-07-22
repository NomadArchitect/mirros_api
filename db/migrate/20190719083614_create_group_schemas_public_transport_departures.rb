class CreateGroupSchemasPublicTransportDepartures < ActiveRecord::Migration[5.2]
  def change
    create_table :group_schemas_public_transport_departures, id: false do |t|
      t.string :uid, primary_key: true
      t.references :public_transport,
                   type: :string,
                   index: { name: 'departures_on_public_transport_id' }
      t.datetime :departure, null: false
      t.integer :delay_minutes
      t.string :line, null: false
      t.string :direction, null: false
      t.string :transit_type
      t.string :platform
    end
  end
end
