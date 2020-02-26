# frozen_string_literal: true

class CreateGroupsSources < ActiveRecord::Migration[5.1]
  def change
    create_table :groups_sources, id: false do |t|
      t.string :group_id, index: true, foreign_key: 'slug'
      t.string :source_id, index: true, foreign_key: 'slug'
    end
  end
end
