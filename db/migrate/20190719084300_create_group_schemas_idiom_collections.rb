class CreateGroupSchemasIdiomCollections < ActiveRecord::Migration[5.2]
  def change
    create_table :group_schemas_idiom_collections, id: false do |t|
      t.string :id, primary_key: true
      t.string :type
      t.string :collection_name
      t.timestamps
    end
  end
end
