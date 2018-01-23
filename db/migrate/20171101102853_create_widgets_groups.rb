class CreateWidgetsGroups < ActiveRecord::Migration[5.1]
  def change
    create_join_table :widgets, :groups
  end
end
