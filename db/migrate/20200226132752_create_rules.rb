class CreateRules < ActiveRecord::Migration[5.2]
  def change
    create_table :rules do |t|
      t.string :provider, null: false
      t.string :field, null: false
      t.string :operator, null: false
      t.json :value, null: false
      t.references :source_instance
      t.references :board, null: false

      t.timestamps
    end
  end
end
