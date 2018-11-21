class CreateGroupSchemasNewsfeedItems < ActiveRecord::Migration[5.2]
  def change
    create_table :group_schemas_newsfeed_items, id: false do |t|
      t.string :guid, primary_key: true
      t.references :newsfeed
      t.string :title
      t.text :content
      t.string :url
      t.datetime :published
    end
    add_index :group_schemas_newsfeed_items, :guid
  end
end
