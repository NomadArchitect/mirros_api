class CreateGroupsCategories < ActiveRecord::Migration[5.1]
  def change
    create_join_table :groups, :categories
  end
end
