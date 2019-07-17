require 'test_helper'
require 'generators/mirros_source/source_generator'

class MirrosSourceGeneratorTest < Rails::Generators::TestCase
  tests MirrosSourceGenerator
  destination Rails.root.join('tmp/generators')
  setup :prepare_destination

  # test "generator runs without errors" do
  #   assert_nothing_raised do
  #     run_generator ["arguments"]
  #   end
  # end
end
