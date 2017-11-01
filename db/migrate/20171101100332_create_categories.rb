class CreateCategories < ActiveRecord::Migration[5.1]
  def change
    create_table :categories do |t|
      t.string :name
      t.string :website
      t.integer :category_id

      t.timestamps
    end
  end
end
