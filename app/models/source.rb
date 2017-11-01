class Source < ApplicationRecord
  has_many :source_instances, dependent: :destroy
end
