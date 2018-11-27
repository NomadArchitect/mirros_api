class CreateSourceInstances < ActiveRecord::Migration[5.1]
  def change
    create_table :source_instances do |t|
      t.string :source_id
      t.string :title
      t.json :configuration
      t.json :options
      t.string :job_id
      t.datetime :last_refresh

      t.timestamps
    end

    add_index :source_instances, :source_id
  end
end
