class CreateSettings < ActiveRecord::Migration[5.2]
  def change
    create_table :settings do |t|
      t.string :slug, null: false
      t.string :category, null: false
      t.string :key, null: false
      t.string :value

      t.timestamps
    end
  end
end
