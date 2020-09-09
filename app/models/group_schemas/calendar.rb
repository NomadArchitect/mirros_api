# frozen_string_literal: true

require 'sti_preload'

module GroupSchemas
  class Calendar < ApplicationRecord
    include StiPreload
    include UpdateOrInsertable
    UPSERT_ASSOC = :events
    ID_FIELD = :uid

    validates :type, presence: true
    has_one :record_link, as: :recordable, dependent: :destroy
    has_many :events,
             class_name: 'CalendarEvent',
             dependent: :delete_all,
             autosave: true
  end
end
