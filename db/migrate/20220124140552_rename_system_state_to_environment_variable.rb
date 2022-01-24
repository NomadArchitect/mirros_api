class RenameSystemStateToEnvironmentVariable < ActiveRecord::Migration[5.2]
  def change
    rename_table :system_states, :environment_variables
  end
end
