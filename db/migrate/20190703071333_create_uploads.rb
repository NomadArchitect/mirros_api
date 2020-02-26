# frozen_string_literal: true

class CreateUploads < ActiveRecord::Migration[5.2]
  def change
    create_table :uploads do |t|
      t.string :type, default: 'Upload'
      t.timestamps
    end
  end
end
