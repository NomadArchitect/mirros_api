class ExtensionBase < ApplicationRecord
  self.abstract_class = true

  validates :name, presence: true, uniqueness: true

  def to_s
    name
  end

  # Returns the class constant for this source's Engine class.
  # @return [Class,nil] The Engine class constant if loaded, nil otherwise.
  def engine_class
    @engine_class ||= find_extension_class(:Engine)
  end

  # Returns the class constant for this source's Hooks implementation.
  # @return [Hooks,nil] The Hooks class constant if loaded, nil otherwise.
  def hooks_class
    @hooks_class ||= find_extension_class(:Hooks)
  end

  # Returns the class constant for this extension's Validator implementation.
  # @return [Validator,nil] The Validator class constant if loaded, nil otherwise.
  def validator_class
    @validator_class ||= find_extension_class(:Validator)
  end

  private

  # Find and constantize the given class from this extension's gem. Searches both the namespaced and
  # non-namespaced version.
  #
  # @param [String,Symbol] type `Engine`, `Hooks` or `Validator`
  # @return [Class,Module,nil] The class constant for the given type.
  def find_extension_class(type)
    # Default case: non-namespaced extension.
    klass_name = "#{name.camelize}::#{type}"

    begin
      klass = klass_name.constantize
    rescue NameError
      # Namespaced extensions
      klass = "Mirros::#{self.class.name}::#{klass_name}".safe_constantize
    end

    klass
  end
end
