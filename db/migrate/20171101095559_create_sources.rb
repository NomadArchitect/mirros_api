class CreateSources < ActiveRecord::Migration[5.1]
  def change
    create_table :sources do |t|
      t.string :name
      t.string :author
      t.string :version
      t.string :website
      t.string :repository

      t.timestamps
    end
  end
end
