module <%= name.camelcase %>
  class ApplicationRecord < ActiveRecord::Base
    self.abstract_class = true
  end
end
