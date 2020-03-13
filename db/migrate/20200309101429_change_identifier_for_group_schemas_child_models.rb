# frozen_string_literal: true

class ChangeIdentifierForGroupSchemasChildModels < ActiveRecord::Migration[5.2]
  TABLES = %w[newsfeed_items calendar_events reminder_items idiom_collection_items current_weather_entries public_transport_departures]

  def up
    TABLES.each do |table|
      # TODO: Check for DB adapter, syntax for Postges is ALTER TABLE <table_name> DROP CONSTRAINT <table_name>_pkey;
      execute "ALTER TABLE group_schemas_#{table} DROP PRIMARY KEY"
      change_column_null "group_schemas_#{table}", :uid, false
      change_table "group_schemas_#{table}" do |t|

        t.primary_key :id
      end
    end
  end

  def down
    TABLES.each do |table|
      remove_column "group_schemas_#{table}", :id
      execute "ALTER TABLE group_schemas_#{table} ADD PRIMARY KEY ( uid )"
    end
  end
end
