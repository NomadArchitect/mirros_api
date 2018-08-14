class CreateCalendars < ActiveRecord::Migration[5.2]
  def change
    create_table :calendars do |t|
      t.string :uid
      t.string :type
      t.string :name
      t.string :description
      t.string :color
    end
  end
end
