class CreateWidgetInstances < ActiveRecord::Migration[5.1]
  def change
    create_table :widget_instances do |t|
      t.integer :widget_id

      t.timestamps
    end

    add_index :widget_instances, :widget_id
  end
end
