# frozen_string_literal: true

require 'test_helper'

class SourcesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @source = sources(:ical)
  end

  test 'should get index' do
    get sources_url, as: :json, headers: jsonapi_headers
    assert_response :success
  end

  test 'should show source' do
    get source_url(@source), as: :json, headers: jsonapi_headers
    assert_response :success
  end

  test 'should update source' do
    patch source_url(@source), params: {
      data: {
        id: @source.id,
        type: 'sources',
        attributes: {
          creator: @source.creator,
          name: @source.name,
          download: @source.download,
          version: @source.version,
          homepage: @source.homepage,
          active: true,
        }
      }
    }, as: :json, headers: jsonapi_headers
    assert_response 200
  end
end
