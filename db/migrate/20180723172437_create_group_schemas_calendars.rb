class CreateGroupSchemasCalendars < ActiveRecord::Migration[5.2]
  def change
    create_table :group_schemas_calendars, id: false do |t|
      t.string :id, primary_key: true
      t.string :type
      t.string :name
      t.string :description
      t.string :color
    end
  end
end
