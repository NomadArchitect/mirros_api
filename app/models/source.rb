class Source < ApplicationRecord
  has_many :source_instances, dependent: :destroy
  belongs_to :category
end
