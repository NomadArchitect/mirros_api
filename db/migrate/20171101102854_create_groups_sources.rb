class CreateGroupsSources < ActiveRecord::Migration[5.1]
  def change
    create_join_table :groups, :sources
  end
end
