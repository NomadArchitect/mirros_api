class CreateGroupsSources < ActiveRecord::Migration[5.1]
  def change
    create_table :groups_sources, id: false do |t|
      t.belongs_to :group, index: true
      t.string :source_id, index: true, foreign_key: 'slug'
    end
  end
end
