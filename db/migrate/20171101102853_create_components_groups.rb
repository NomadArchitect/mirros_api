class CreateComponentsGroups < ActiveRecord::Migration[5.1]
  def change
    create_join_table :components, :groups
  end
end
