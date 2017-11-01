class CreateGroups < ActiveRecord::Migration[5.1]
  def change
    create_table :groups do |t|
      t.string :name
      t.integer :source_id
      t.integer :component_id
      t.integer :category_id

      t.timestamps
    end
  end
end
