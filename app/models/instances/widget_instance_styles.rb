# frozen_string_literal: true

# Sub-model for style settings of a WidgetInstance.
class WidgetInstanceStyles
  include StoreModel::Model

  attribute :font_color,
            :string,
            default: Setting.find_by(slug: 'system_fontcolor')&.value || '#ffffff'
  attribute :background_blur, :boolean, default: false
  attribute :font_size, :integer, default: 100
  attribute :horizontal_align, :string, default: 'left'
  attribute :vertical_align, :string, default: 'top'

  validates :font_color,
            allow_blank: true,
            format: {
              with: /\#([0-9a-f]{6})/,
              message: 'must be a hex value, e.g. #ff0000'
            }
  validates :font_size, numericality: { only_integer: true, greater_than_or_equal_to: 100 }
  validates :horizontal_align, inclusion: {
    in: %w[left right center justify],
    message: 'must be one of ["left", "right", "center", "justify"]'
  }
  validates :vertical_align, inclusion: {
    in: %w[top bottom center stretch],
    message: 'must be one of ["top", "bottom", "center", "stretch"]'
  }
  validates :background_blur,
            inclusion: {
              in: [true, false],
              message: 'must be one of [true, false]'
            }
  # FIXME: String/Array values for the background_blur attribute are coerced to Boolean
  #  at some point in the attribute setup stack, which lets them pass validation. Only `null` fails.
end
