class CreateServices < ActiveRecord::Migration[5.1]
  def change
    create_table :services do |t|
      t.string :status
      t.json :parameters

      t.timestamps
    end
  end
end
