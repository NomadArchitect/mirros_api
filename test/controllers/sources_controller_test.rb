require 'test_helper'

class SourcesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @source = sources(:ical)
    @request.headers['Content-Type'] = 'application/vnd.api+json'
  end

  test "should get index" do
    get sources_url, as: :json
    assert_response :success
  end

  test "should create source" do
    assert_difference('Source.count') do
      post sources_url, params: {source: {creator: @source.creator, name: @source.name, download: @source.download, version: @source.version, homepage: @source.homepage}}, as: :json
    end

    assert_response 201
  end

  test "should show source" do
    get source_url(@source), as: :json
    assert_response :success
  end

  test "should update source" do
    patch source_url(@source), params: {
      source: {
        creator: @source.creator,
        name: @source.name,
        download: @source.download,
        version: @source.version,
        homepage: @source.homepage
      }
    }, as: :json
    assert_response 200
  end

  test "should destroy source" do
    assert_difference('Source.count', -1) do
      delete source_url(@source), as: :json
    end

    assert_response 204
  end
end
