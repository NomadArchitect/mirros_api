class CreateComponentsCategories < ActiveRecord::Migration[5.1]
  def change
    create_join_table :components, :categories
  end
end
