require 'test_helper'

class ComponentInstancesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @component_instance = component_instances(:one)
  end

  test "should get index" do
    get component_instances_url, as: :json
    assert_response :success
  end

  test "should create component_instance" do
    assert_difference('ComponentInstance.count') do
      post component_instances_url, params: { component_instance: {  } }, as: :json
    end

    assert_response 201
  end

  test "should show component_instance" do
    get component_instance_url(@component_instance), as: :json
    assert_response :success
  end

  test "should update component_instance" do
    patch component_instance_url(@component_instance), params: { component_instance: {  } }, as: :json
    assert_response 200
  end

  test "should destroy component_instance" do
    assert_difference('ComponentInstance.count', -1) do
      delete component_instance_url(@component_instance), as: :json
    end

    assert_response 204
  end
end
