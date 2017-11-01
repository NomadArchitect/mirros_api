class CreateComponentInstances < ActiveRecord::Migration[5.1]
  def change
    create_table :component_instances do |t|
      t.integer :component_id
      
      t.timestamps
    end
  end
end
