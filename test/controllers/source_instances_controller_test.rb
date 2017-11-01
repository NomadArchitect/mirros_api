require 'test_helper'

class SourceInstancesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @source_instance = source_instances(:one)
  end

  test "should get index" do
    get source_instances_url, as: :json
    assert_response :success
  end

  test "should create source_instance" do
    assert_difference('SourceInstance.count') do
      post source_instances_url, params: { source_instance: {  } }, as: :json
    end

    assert_response 201
  end

  test "should show source_instance" do
    get source_instance_url(@source_instance), as: :json
    assert_response :success
  end

  test "should update source_instance" do
    patch source_instance_url(@source_instance), params: { source_instance: {  } }, as: :json
    assert_response 200
  end

  test "should destroy source_instance" do
    assert_difference('SourceInstance.count', -1) do
      delete source_instance_url(@source_instance), as: :json
    end

    assert_response 204
  end
end
