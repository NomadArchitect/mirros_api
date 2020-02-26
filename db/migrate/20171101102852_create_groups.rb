# frozen_string_literal: true

class CreateGroups < ActiveRecord::Migration[5.1]
  def change
    create_table :groups, id: false do |t|
      t.string :name, primary_key: true
      t.string :slug

      t.timestamps
    end
  end
end
