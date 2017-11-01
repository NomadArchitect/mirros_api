class CreateGroupsSources < ActiveRecord::Migration[5.1]
  def change
    create_table :groups_sources, id: false do |t|
      t.integer :group_id
      t.integer :source_id

      t.timestamps
    end
  end
end
