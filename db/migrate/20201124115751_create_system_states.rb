class CreateSystemStates < ActiveRecord::Migration[5.2]
  def change
    create_table :system_states do |t|
      t.string :variable, null: false, index: true
      t.json :value, null: false
      t.timestamps
    end
  end
end
