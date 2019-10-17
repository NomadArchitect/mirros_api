class CreateNmNetworks < ActiveRecord::Migration[5.2]
  def change
    create_table :nm_networks, id: false do |t|
      t.string :uuid, primary_key: true
      t.string :connection_id, null: false
      t.string :interface_type, null: false
      t.string :devices
      t.boolean :active
      t.string :ip4_address
      t.string :ip6_address

      t.timestamps
    end
  end
end
