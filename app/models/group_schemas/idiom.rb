module GroupSchemas
  class Idiom < ApplicationRecord
    has_one :record_link, as: :recordable, dependent: :destroy
  end
end
