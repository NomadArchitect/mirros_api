class RotateActiveBoardJob < ApplicationJob
  queue_as :system

  def perform(*_args)
    active_board_setting = Setting.find_by(slug: :system_activeboard)
    boards = Board.ids
    new_board_id = boards[boards.find_index(active_board_setting.value.to_i) + 1] || boards.first
    active_board_setting.update(value: new_board_id)
  end
end
