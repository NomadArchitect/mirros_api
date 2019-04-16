class CreateGroupSchemasIdioms < ActiveRecord::Migration[5.2]
  def change
    create_table :group_schemas_idioms do |t|
      t.string :title
      t.text :message
      t.string :author
      t.string :language
      t.date :date

      t.timestamps
    end
  end
end
