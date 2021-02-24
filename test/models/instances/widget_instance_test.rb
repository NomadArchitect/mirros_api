require 'test_helper'

class
WidgetInstanceTest < ActiveSupport::TestCase
  fixtures :boards, :widgets, :widget_instances

  test 'creates default styles if client does not provide them' do
    wi = WidgetInstance.new
    assert wi.styles.present? && wi.styles.instance_of?(WidgetInstanceStyles)
  end

  test 'validates style properties' do
    valid_wi = widget_instances(:valid_styles)
    valid_wi.save

    assert valid_wi.valid?

    invalid_wi = widget_instances :invalid_styles
    invalid_wi.save

    assert_invalid invalid_wi,
                   font_color: 'must be a hex value, e.g. #ff0000',
                   font_size: 'must be greater than or equal to 100',
                   text_align: 'must be one of ["left", "right", "center", "justify"]',
                   background_blur: 'must be one of [true, false]'
  end
end
