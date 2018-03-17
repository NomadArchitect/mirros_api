class CreateServices < ActiveRecord::Migration[5.1]
  def change
    create_table :services do |t|
      t.string :status
      t.json :parameters
      t.integer :widget_id

      t.timestamps
    end

    add_index :services, :widget_id
  end
end
