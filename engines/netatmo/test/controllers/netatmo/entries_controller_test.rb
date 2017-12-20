require 'test_helper'

module Netatmo
  class EntriesControllerTest < ActionDispatch::IntegrationTest
    include Engine.routes.url_helpers

    setup do
      @entry = netatmo_entries(:one)
    end

    test "should get index" do
      get entries_url
      assert_response :success
    end

    test "should get new" do
      get new_entry_url
      assert_response :success
    end

    test "should create entry" do
      assert_difference('Entry.count') do
        post entries_url, params: { entry: { name: @entry.name, text: @entry.text } }
      end

      assert_redirected_to entry_url(Entry.last)
    end

    test "should show entry" do
      get entry_url(@entry)
      assert_response :success
    end

    test "should get edit" do
      get edit_entry_url(@entry)
      assert_response :success
    end

    test "should update entry" do
      patch entry_url(@entry), params: { entry: { name: @entry.name, text: @entry.text } }
      assert_redirected_to entry_url(@entry)
    end

    test "should destroy entry" do
      assert_difference('Entry.count', -1) do
        delete entry_url(@entry)
      end

      assert_redirected_to entries_url
    end
  end
end
