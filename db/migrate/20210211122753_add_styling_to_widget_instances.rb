class AddStylingToWidgetInstances < ActiveRecord::Migration[5.2]
  def change
    add_column :widget_instances, :styles, :json, null: true, after: :showtitle
  end
end
