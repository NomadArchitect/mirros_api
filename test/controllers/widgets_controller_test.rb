require 'test_helper'

class WidgetsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @widget = widgets(:calendar_event_list)
    @request.headers['Content-Type'] = 'application/vnd.api+json'
  end

  test "should get index" do
    get widgets_url, as: :json
    assert_response :success
  end

  test "should show widget" do
    get widget_url(@widget), as: :json
    assert_response :success
  end

  test "should update widget" do
    patch widget_url(@widget), params: { widget: { author: @widget.author, name: @widget.name, repository: @widget.repository, version: @widget.version, homepage: @widget.homepage } }, as: :json
    assert_response 200
  end
end
