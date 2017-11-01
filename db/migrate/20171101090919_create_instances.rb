class CreateInstances < ActiveRecord::Migration[5.1]
  def change
    create_table :instances do |t|
      t.string :type
      t.integer :category_id

      t.timestamps
    end
  end
end
