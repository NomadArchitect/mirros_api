class DropNmNetworksTable < ActiveRecord::Migration[5.2]
  def change
    drop_table :nm_networks if table_exists? :nm_networks
  end
end
