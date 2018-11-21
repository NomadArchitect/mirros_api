class CreateGroupSchemasCalendars < ActiveRecord::Migration[5.2]
  def change
    create_table :group_schemas_calendars do |t|
      t.string :uid
      t.string :type
      t.string :name
      t.string :description
      t.string :color
    end
    add_index :group_schemas_calendars, :uid
  end
end
