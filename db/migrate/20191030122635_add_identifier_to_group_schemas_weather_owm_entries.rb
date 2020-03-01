# frozen_string_literal: true

class AddIdentifierToGroupSchemasWeatherOwmEntries < ActiveRecord::Migration[5.2]
  def change
    change_table :group_schemas_weather_owm_entries, bulk: true do |t|
      execute 'ALTER TABLE group_schemas_weather_owm_entries DROP PRIMARY KEY'
      # TODO: Maybe add conditional check for DB adapter, since syntax for Postges is
      # ALTER TABLE <table_name> DROP CONSTRAINT <table_name>_pkey;
      t.primary_key :id
    end
  end
end
