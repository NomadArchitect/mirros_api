# frozen_string_literal: true

class AddBoardRefToWidgetInstance < ActiveRecord::Migration[5.2]
  def change
    add_belongs_to :widget_instances, :board
  end
end
