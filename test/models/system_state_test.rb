require 'test_helper'

class SystemStateTest < ActiveSupport::TestCase
  test 'should not save without variable' do
    system_state = EnvironmentVariable.new
    assert_raises ActiveRecord::NotNullViolation, 'Saved the system state without a variable' do
      system_state.save
    end
  end

  test 'should not save without value' do
    system_state = EnvironmentVariable.new variable: 'test_variable'
    assert_raises ActiveRecord::NotNullViolation, 'Saved the system state without a value' do
      system_state.save
    end
  end

  test 'saves value column as JSON' do
    system_states(:client_display)
    assert EnvironmentVariable.find_by(variable: 'client_display').value.instance_of?(Hash)
  end

  test 'validates uniqueness of variable field' do
    system_states(:client_display)
    assert_raises ActiveRecord::RecordInvalid, 'saved a duplicate variable name' do
      EnvironmentVariable.create! variable: 'client_display', value: {}
    end
  end

  test 'retrieves nested values' do
    state = system_states(:client_display)
    # RuboCop mistakes custom EnvironmentVariable.dig call with Hash.dig, disable rule.
    # rubocop:disable Style/SingleArgumentDig
    assert_equal state.value['orientation'],
                 EnvironmentVariable.dig(variable: 'client_display', key: 'orientation')
    # rubocop:enable Style/SingleArgumentDig
  end

  test 'retrieves single values' do
    state = system_states(:simple_state)
    assert_equal state.value, EnvironmentVariable.get_value('simple_state')
  end
end
