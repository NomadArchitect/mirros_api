require 'test_helper'

class SourceInstancesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @source = sources(:ical)
    @source_instance = source_instances(:ical_1)
    set_jsonapi_headers
  end

  test "should get index" do
    get source_instances_url, headers: @headers, as: :json
    assert_response :success
  end

  test "should NOT create source_instance if source is NOT present" do
    post source_instances_url,
         params: {
           data: {
             type: 'source-instances',
             attributes: {
               title: 'an invalid instance',
               configuration: {}
             },
             relationships: {
               source: {
                 data: {
                   type: 'sources',
                   id: 'non-existent-source'
                 }
               }
             }
           }
         },
         headers: @headers,
         as: :json
    assert_response 422
  end

  test "should create source_instance if source is present" do
    assert_difference('SourceInstance.count') do
      post source_instances_url,
           params: {
             data: {
               type: 'source-instances',
               attributes: {
                 title: 'a new instance',
                 configuration: {}
               },
               relationships: {
                 source: {
                   data: {
                     type: 'sources',
                     id: @source.name
                   }
                 }
               }
             }
           },
           headers: @headers,
           as: :json
    end
    assert_response 201
  end

  test "should show source_instance" do
    get source_instance_url(@source_instance), headers: @headers, as: :json
    assert_response :success
  end

  test "should update source_instance" do
    patch source_instance_url(@source_instance),
          params: {
            data: {
              id: @source_instance.id,
              type: 'source-instances',
              attributes: {
                title: @source_instance.title.reverse
              }
            }
          },
          headers: @headers,
          as: :json
    assert_response 200
  end

  test "should destroy source_instance" do
    assert_difference('SourceInstance.count', -1) do
      delete source_instance_url(@source_instance), headers: @headers, as: :json
    end

    assert_response 204
  end
end
