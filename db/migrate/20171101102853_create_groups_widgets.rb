class CreateGroupsWidgets < ActiveRecord::Migration[5.1]
  def change
    create_table :groups_widgets, id: false do |t|
      t.string :group_id, index: true, foreign_key: 'slug'
      t.string :widget_id, index: true, foreign_key: 'slug'
    end

  end
end
