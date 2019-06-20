module GroupSchemas
  class Newsfeed < ApplicationRecord
    validates_presence_of :type
    has_many :items, class_name: 'NewsfeedItem', dependent: :delete_all, autosave: true
    has_one :record_link, as: :recordable, dependent: :destroy
  end
end
