require 'test_helper'

class UploadsControllerTest < ActionDispatch::IntegrationTest
  test "user can upload files" do
    assert Upload.count.eql? 0

    post '/uploads', params: { upload: { file: fixture_file_upload('files/glancr_logo.png', 'image/png') } }

    assert Upload.count.eql? 1
    assert_response :created
    assert @response.parsed_body['content_type'].eql? 'image/png'
  end

  test "uploaded files are cacheable" do
    post '/uploads', params: { upload: { file: fixture_file_upload('files/glancr_logo.png', 'image/png') } }

    get @response.parsed_body['file_url']
    follow_redirect!

    assert @response.cache_control[:public].eql? true
    assert @response.cache_control[:max_age].to_i > 0
  end
end
