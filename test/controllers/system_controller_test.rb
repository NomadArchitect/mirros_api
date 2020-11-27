require 'test_helper'

class SystemControllerTest < ActionDispatch::IntegrationTest
  test 'reads default extension instances from a YAML file' do
    controller = SystemController.new
    assert_nothing_raised do
      controller.send(:load_defaults_file)
    end
    assert_not_nil controller.instance_variable_get(:@defaults)
  end
end
