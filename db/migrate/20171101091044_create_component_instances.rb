class CreateComponentInstances < ActiveRecord::Migration[5.1]
  def change
    create_table :component_instances do |t|

      t.timestamps
    end
  end
end
