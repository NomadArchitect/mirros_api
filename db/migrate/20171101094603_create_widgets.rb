class CreateWidgets < ActiveRecord::Migration[5.1]
  def change
    create_table :widgets do |t|
      t.string :name, null: false
      t.json :title
      t.string :compatibility
      t.json :description
      t.json :sizes # TODO: Disable nullable once dev docs are final
      t.boolean :single_source, default: false
      t.string :version
      t.string :creator
      t.string :homepage
      t.string :download
      t.string :slug
      t.string :icon
      t.string :languages, array: true
      t.string :group_id, index: true, foreign_key: 'slug'

      t.timestamps
    end
    add_index :widgets, :slug, unique: true
  end
end
