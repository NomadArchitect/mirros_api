# frozen_string_literal: true

require 'sti_preload'

module GroupSchemas
  class Newsfeed < ApplicationRecord
    include StiPreload
    include UpdateOrInsertable
    UPSERT_ASSOC = :items
    ID_FIELD = :uid

    validates :type, presence: true
    has_one :record_link, as: :recordable, dependent: :destroy
    has_many :items, class_name: 'NewsfeedItem', dependent: :delete_all, autosave: true
  end
end
