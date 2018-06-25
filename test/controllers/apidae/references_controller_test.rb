require 'test_helper'

module Apidae
  class ReferencesControllerTest < ActionDispatch::IntegrationTest
    include Engine.routes.url_helpers

    test "should get index" do
      get apidae_references_index_url
      assert_response :success
    end

  end
end
