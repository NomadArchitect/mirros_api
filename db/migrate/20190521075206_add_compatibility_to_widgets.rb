class AddCompatibilityToWidgets < ActiveRecord::Migration[5.2]
  def change
    add_column :widgets, :compatibility, :string
  end
end
