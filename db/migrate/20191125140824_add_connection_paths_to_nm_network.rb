# frozen_string_literal: true

class AddConnectionPathsToNmNetwork < ActiveRecord::Migration[5.2]
  def change
    change_table :nm_networks, bulk: true do |t|
      t.string :active_connection_path
      t.string :connection_settings_path
    end
  end
end
