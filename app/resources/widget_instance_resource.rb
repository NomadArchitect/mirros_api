# frozen_string_literal: true

# JSONAPI::Resource class for WidgetInstance model.
class WidgetInstanceResource < JSONAPI::Resource
  attributes :title, :showtitle, :configuration, :position, :styles
  has_one :widget, exclude_links: [:self]
  has_one :board, exclude_links: [:self]
  has_one :group, through: :widget, foreign_key_on: :widget, exclude_links: [:self]
  has_many :instance_associations, always_include_linkage_data: true, exclude_links: [:self]
  has_many :source_instances,
           through: :instance_associations,
           always_include_linkage_data: true,
           exclude_links: [:self]

  exclude_links :default

  # Getter for the style attribute. Transforms keys to camelCase for consistency.
  # @return [Hash{String => String,TrueClass,FalseClass,Integer}] Style attributes
  def styles
    @model.styles.attributes.transform_keys { |key| key.to_s.camelize(:lower) }
  end

  # Getter for the configuration attribute. Transforms keys to camelCase for consistency.
  # @return [Hash{String => String,TrueClass,FalseClass,Integer}] Configuration attributes
  def configuration
    if @model.configuration&.respond_to?(:attributes)
      @model.configuration.attributes.except('_model').transform_keys { |key| key.to_s.camelize(:lower) }
    else
      @model.configuration
    end
  end

  # Setter for the style attribute.
  # @param [ActionController::Parameters] new_styles
  # @raise [JSONAPI::Exceptions::InvalidField] if attempting to set an unknown style property
  def styles=(new_styles)
    new_styles.each_pair do |key, value|
      method_name = "#{key.underscore.to_sym}="
      unless @model.styles.respond_to? method_name
        raise JSONAPI::Exceptions::InvalidField.new(
          'widget-instances',
          "styles.#{method_name.delete_suffix('=')}"
        )
      end

      @model.styles.public_send method_name, value
    end
  end

  # Setter for the configuration attribute.
  # @param [ActionController::Parameters] new_configuration
  # @raise [JSONAPI::Exceptions::InvalidField] if attempting to set an unknown configuration property
  def configuration=(new_configuration)
    new_configuration.each_pair do |key, value|
      method_name = "#{key.underscore.to_sym}="

      # Discard changes to the StoreModel.
      raise JSONAPI::Exceptions::ParameterNotAllowed.new('_model') if key.eql? '_model'

      if @model.configuration.respond_to?(method_name)
        @model.configuration.public_send method_name, value
      else
        raise JSONAPI::Exceptions::InvalidField.new(
          'widget-instances',
          "configuration.#{method_name.delete_suffix('=')}"
        )
      end
    end
  end
end
