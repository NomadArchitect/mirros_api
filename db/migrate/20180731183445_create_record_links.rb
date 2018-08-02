class CreateRecordLinks < ActiveRecord::Migration[5.2]
  def change
    create_table :record_links do |t|
      t.references :recordable, polymorphic: true, index: true
      t.references :source_instance, index: true, foreign_key: true
      t.string :group_id, index: true, foreign_key: true
    end
  end
end
