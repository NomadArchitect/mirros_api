module GroupSchemas
  class NewsfeedItem < ApplicationRecord
    belongs_to :newsfeed
  end
end
