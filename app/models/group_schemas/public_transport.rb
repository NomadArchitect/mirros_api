module GroupSchemas
  class PublicTransport < ApplicationRecord
    validates_presence_of :type
    has_one :record_link, as: :recordable, dependent: :destroy
  end
end
