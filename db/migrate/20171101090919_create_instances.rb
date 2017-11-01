class CreateInstances < ActiveRecord::Migration[5.1]
  def change
    create_table :instances do |t|

      t.timestamps
    end
  end
end
