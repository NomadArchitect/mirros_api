# frozen_string_literal: true

# Configuration of a WidgetInstance. Must be subclassed by Widget extension.
class WidgetInstanceConfiguration
  include StoreModel::Model

  def self.inherited(subclass)
    subclass.attribute :_model, :string, default: subclass
    subclass.validates :_model, presence: true
  end
end
