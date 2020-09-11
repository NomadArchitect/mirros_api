class RenameSourceToDataSource < ActiveRecord::Migration[6.0]
  def change
    # primary table
    rename_table :sources, :data_sources unless table_exists? :data_sources
    #rename_index :data_sources, :index_sources_on_slug,:index_data_sources_on_slug

    # join table for group association
    rename_table :groups_sources, :data_sources_groups unless table_exists? :data_sources_groups
    rename_column :data_sources_groups, :source_id, :data_source_id

    rename_column :source_instances, :source_id, :data_source_id
    # foreign keys on related models
    #rename_column_indexes :source_instances, :source_id, :data_source_id
  end
end
