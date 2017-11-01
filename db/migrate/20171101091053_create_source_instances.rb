class CreateSourceInstances < ActiveRecord::Migration[5.1]
  def change
    create_table :source_instances do |t|
      t.integer :source_id

      t.timestamps
    end
  end
end
