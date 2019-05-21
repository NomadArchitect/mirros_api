class AddCompatibilityToSources < ActiveRecord::Migration[5.2]
  def change
    add_column :sources, :compatibility, :string
  end
end
