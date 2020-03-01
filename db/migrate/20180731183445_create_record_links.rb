# frozen_string_literal: true

class CreateRecordLinks < ActiveRecord::Migration[5.2]
  def change
    create_table :record_links do |t|
      t.references :source_instance, index: true
      t.references :group, type: :string, index: true
      t.references :recordable, type: :string, polymorphic: true
    end
  end
end
