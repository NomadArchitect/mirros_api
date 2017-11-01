require 'test_helper'

class InstancesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @instance = instances(:one)
  end

  test "should get index" do
    get instances_url, as: :json
    assert_response :success
  end

  test "should create instance" do
    assert_difference('Instance.count') do
      post instances_url, params: { instance: {  } }, as: :json
    end

    assert_response 201
  end

  test "should show instance" do
    get instance_url(@instance), as: :json
    assert_response :success
  end

  test "should update instance" do
    patch instance_url(@instance), params: { instance: {  } }, as: :json
    assert_response 200
  end

  test "should destroy instance" do
    assert_difference('Instance.count', -1) do
      delete instance_url(@instance), as: :json
    end

    assert_response 204
  end
end
