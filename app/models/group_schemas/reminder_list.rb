# frozen_string_literal: true

require 'sti_preload'

module GroupSchemas
  class ReminderList < ApplicationRecord
    include StiPreload
    include UpdateOrInsertable
    UPSERT_ASSOC = :reminders
    ID_FIELD = :uid

    validates :type, presence: true
    has_one :record_link, as: :recordable, dependent: :destroy
    has_many :reminders, class_name: 'ReminderItem', dependent: :delete_all, autosave: true
  end
end
