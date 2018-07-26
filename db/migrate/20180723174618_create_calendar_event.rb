class CreateCalendarEvent < ActiveRecord::Migration[5.2]
  def change
    create_table :calendar_events do |t|
      t.references :calendar
      t.datetime :dtstart
      t.datetime :dtend
      t.string :summary
      t.string :description
    end
  end
end
