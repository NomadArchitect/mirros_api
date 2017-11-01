class CreateComponentsGroups < ActiveRecord::Migration[5.1]
  def change
    create_table :components_groups, id: false do |t|
      t.integer :component_id
      t.integer :group_id

      t.timestamps
    end
  end
end
