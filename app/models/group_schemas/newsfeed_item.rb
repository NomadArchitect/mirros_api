module GroupSchemas
  class NewsfeedItem < ApplicationRecord
    belongs_to :newsfeed

    def serializable_hash(options = nil)
      base = super({except: %i[guid newsfeed_id published]}.merge(options || {}))
      base.merge(
        published: published.iso8601
      )
    end
  end
end
