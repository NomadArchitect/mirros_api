# frozen_string_literal: true

module GroupSchemas
  class Newsfeed < ApplicationRecord
    include UpdateOrInsertable
    UPSERT_ASSOC = :items
    ID_FIELD = :uid

    validates :type, presence: true
    has_one :record_link, as: :recordable, dependent: :destroy
    has_many :items, class_name: 'NewsfeedItem', dependent: :delete_all, autosave: true
  end
end
