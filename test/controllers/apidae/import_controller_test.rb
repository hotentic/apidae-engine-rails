require 'test_helper'

module Apidae
  class Apidae::ImportControllerTest < ActionController::TestCase
    setup do
      @routes = Engine.routes
    end

    test "should get callback" do
      get :callback
      assert_response :success
    end

  end
end
