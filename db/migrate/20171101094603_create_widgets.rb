class CreateWidgets < ActiveRecord::Migration[5.1]
  def change
    create_table :widgets do |t|
      t.string :name
      t.string :icon
      t.string :version
      t.string :creator
      t.string :website
      t.string :languages, array: true, default: ['en_GB']
      t.boolean :installed, default: false

      t.timestamps
    end
  end
end
