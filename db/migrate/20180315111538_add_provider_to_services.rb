class AddProviderToServices < ActiveRecord::Migration[5.1]
  def change
    add_reference :services, :provider, foreign_key: { to_table: :widgets }
  end
end
