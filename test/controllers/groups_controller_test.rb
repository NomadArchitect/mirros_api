# frozen_string_literal: true

require 'test_helper'

class GroupsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @group = groups(:calendar)
  end

  test 'should get index' do
    get groups_url, as: :json, headers: jsonapi_headers
    assert_response :success
  end

  test 'should create group' do
    assert_difference('Group.count') do
      post groups_url, params: { group: { category_id: @group.category_id, widget_id: @group.widget_id, id: @group.id, source_id: @group.source_id } }, as: :json, headers: jsonapi_headers
    end

    assert_response 201
  end

  test 'should show group' do
    get group_url(@group), as: :json
    assert_response :success
  end

  test 'should update group' do
    patch group_url(@group), params: { group: { category_id: @group.category_id, widget_id: @group.widget_id, id: @group.id, source_id: @group.source_id } }, as: :json, headers: jsonapi_headers
    assert_response 200
  end

  test 'should destroy group' do
    assert_difference('Group.count', -1) do
      delete group_url(@group), as: :json, headers: jsonapi_headers
    end

    assert_response 204
  end
end
