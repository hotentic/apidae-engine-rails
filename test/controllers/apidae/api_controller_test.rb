require 'test_helper'

module Apidae
  class ApiControllerTest < ActionDispatch::IntegrationTest
    include Engine.routes.url_helpers

    test "should get selection" do
      get api_selection_url
      assert_response :success
    end

    test "should get object" do
      get api_object_url
      assert_response :success
    end

    test "should get agenda" do
      get api_agenda_url
      assert_response :success
    end

  end
end
