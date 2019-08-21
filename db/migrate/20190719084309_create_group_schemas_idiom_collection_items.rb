class CreateGroupSchemasIdiomCollectionItems < ActiveRecord::Migration[5.2]
  def change
    create_table :group_schemas_idiom_collection_items, id: false do |t|
      t.string :uid, primary_key: true
      t.references :idiom_collection, type: :string, index: { name: 'items_on_idiom_collection_id' }
      t.string :title
      t.text :message
      t.text :author
      t.string :language
      t.date :date
      t.timestamps
    end
  end
end
