class CreateSources < ActiveRecord::Migration[5.1]
  def change
    create_table :sources do |t|
      t.string :name, null: false
      t.json :title, null: false
      t.json :description, null: false
      t.string :creator
      t.string :version, null: false
      t.string :website
      t.string :download, null: false
      t.string :slug, null: false

      t.timestamps
    end
    add_index :sources, :slug, unique: true
  end
end
