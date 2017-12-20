class CreateSourcesCategories < ActiveRecord::Migration[5.1]
  def change
    create_join_table :sources, :categories
  end
end
