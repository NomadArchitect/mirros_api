class CreateWidgets < ActiveRecord::Migration[5.1]
  def change
    create_table :widgets do |t|
      t.string :name, null: false
      t.json :title, null: false
      t.json :description, null: false
      t.string :version, null: false
      t.string :creator
      t.string :website
      t.string :download, null: false
      t.string :slug, null: false
      t.string :icon
      t.string :languages, array: true, default: ['en_GB']
      t.string :group_id, null: false, index: true, foreign_key: 'slug'

      t.timestamps
    end
    add_index :widgets, :slug, :unique => true
  end
end
