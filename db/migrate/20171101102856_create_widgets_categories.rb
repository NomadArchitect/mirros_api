class CreateWidgetsCategories < ActiveRecord::Migration[5.1]
  def change
    create_join_table :widgets, :categories
  end
end
