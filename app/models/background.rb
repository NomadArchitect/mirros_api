# frozen_string_literal: true

# Board background image file entities.
class Background < Upload
  has_many :boards,
           inverse_of: :background,
           foreign_key: :uploads_id,
           dependent: :nullify
end
