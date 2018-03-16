class CreateCategoriesWidgets < ActiveRecord::Migration[5.1]
  def change
    create_join_table :categories, :widgets
  end
end
