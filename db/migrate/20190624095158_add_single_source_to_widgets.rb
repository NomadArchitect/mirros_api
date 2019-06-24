class AddSingleSourceToWidgets < ActiveRecord::Migration[5.2]
  def change
    add_column :widgets, :single_source, :boolean, default: false
  end
end
