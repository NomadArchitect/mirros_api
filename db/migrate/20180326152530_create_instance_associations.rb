class CreateInstanceAssociations < ActiveRecord::Migration[5.1]
  def change
    create_table :instance_associations do |t|
      t.json :configuration
      t.string :group_id, null: false, index: true, foreign_key: 'slug'
      t.references :widget_instance, null: false, index: true, foreign_key: true
      t.references :source_instance, null: false, index: true, foreign_key: true
      t.timestamps
    end
  end
end
