class CreateCalendarEvent < ActiveRecord::Migration[5.2]
  def change
    create_table :calendar_events, id: false do |t|
      t.primary_key :uid
      t.references :calendar
      t.datetime :dtstart
      t.datetime :dtend
      t.boolean :all_day
      t.string :summary
      t.string :description
    end
  end
end
