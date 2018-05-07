class CreateWidgetInstances < ActiveRecord::Migration[5.1]
  def change
    create_table :widget_instances do |t|
      t.string :widget_id
      t.json :configuration
      t.json :position
      t.timestamps
    end

    add_index :widget_instances, :widget_id
  end
end
