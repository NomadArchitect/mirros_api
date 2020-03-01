# frozen_string_literal: true

class IncreaseUrlLengthOnGroupSchemasNewsfeedItems < ActiveRecord::Migration[5.2]
  def change
    change_column :group_schemas_newsfeed_items, :url, :string, limit: 700
  end
end
