require 'test_helper'
require 'generators/mirros_widget/mirros_widget_generator'

class MirrosWidgetGeneratorTest < Rails::Generators::TestCase
  tests MirrosWidgetGenerator
  destination Rails.root.join('tmp/generators')
  setup :prepare_destination

  # test "generator runs without errors" do
  #   assert_nothing_raised do
  #     run_generator ["arguments"]
  #   end
  # end
end
