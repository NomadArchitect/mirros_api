require 'test_helper'

class WidgetTest < ActiveSupport::TestCase
  test "should not save without name" do
    widget = Widget.new
    assert_not widget.save, 'Saved the widget without a name'
  end
end
