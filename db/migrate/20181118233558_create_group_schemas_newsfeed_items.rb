class CreateGroupSchemasNewsfeedItems < ActiveRecord::Migration[5.2]
  def change
    create_table :group_schemas_newsfeed_items, id: false do |t|
      t.string :uid, primary_key: true
      t.references :newsfeed, type: :string
      t.string :title
      t.text :content
      t.string :url
      t.datetime :published
    end
  end
end
