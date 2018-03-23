class CreateWidgets < ActiveRecord::Migration[5.1]
  def change
    create_table :widgets do |t|
      t.string :name, null: false
      t.string :icon
      t.string :version, null: false
      t.string :creator
      t.string :website
      t.string :download, null: false
      t.string :slug
      t.string :languages, array: true, default: ['en_GB']

      t.timestamps
    end
  end
end
