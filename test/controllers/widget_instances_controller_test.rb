require 'test_helper'

class WidgetInstancesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @widget_instance = widget_instances(:one)
  end

  test "should get index" do
    get widget_instances_url, as: :json
    assert_response :success
  end

  test "should create widget_instance" do
    assert_difference('WidgetInstance.count') do
      post widget_instances_url, params: { widget_instance: {  } }, as: :json
    end

    assert_response 201
  end

  test "should show widget_instance" do
    get widget_instance_url(@widget_instance), as: :json
    assert_response :success
  end

  test "should update widget_instance" do
    patch widget_instance_url(@widget_instance), params: { widget_instance: {  } }, as: :json
    assert_response 200
  end

  test "should destroy widget_instance" do
    assert_difference('WidgetInstance.count', -1) do
      delete widget_instance_url(@widget_instance), as: :json
    end

    assert_response 204
  end
end
