class AddIndexToSettingsSlug < ActiveRecord::Migration[5.2]
  def change
    add_index :settings, :slug, unique: true
  end
end
