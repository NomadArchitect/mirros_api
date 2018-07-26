class CreateCalendar < ActiveRecord::Migration[5.2]
  def change
    create_table :calendars do |t|
      t.string :type
      t.string :name
      t.string :description
      t.string :color
      t.references :source_instance
      #t.references :validatable, polymorphic: true, index: true
    end
  end
end
