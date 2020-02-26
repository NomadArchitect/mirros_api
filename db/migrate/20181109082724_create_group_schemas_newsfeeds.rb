# frozen_string_literal: true

class CreateGroupSchemasNewsfeeds < ActiveRecord::Migration[5.2]
  def change
    create_table :group_schemas_newsfeeds, id: false do |t|
      t.string :id, primary_key: true
      t.string :type
      t.string :name
      t.string :url, null: false
      t.string :icon_url
      t.datetime :latest_entry
      t.timestamps
    end
    add_index :group_schemas_newsfeeds, :url
  end
end
