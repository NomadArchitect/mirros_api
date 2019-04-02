class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true
  after_save :set_refresh_flag
  after_destroy :set_refresh_flag

  def set_refresh_flag
    StateCache.s.refresh_frontend = true
  end
end
