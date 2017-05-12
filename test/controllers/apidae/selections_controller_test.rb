require 'test_helper'

module Apidae
  class SelectionsControllerTest < ActionController::TestCase
    setup do
      @selection = apidae_selections(:one)
      @routes = Engine.routes
    end

    test "should get index" do
      get :index
      assert_response :success
      assert_not_nil assigns(:selections)
    end

    test "should get new" do
      get :new
      assert_response :success
    end

    test "should create selection" do
      assert_difference('Selection.count') do
        post :create, selection: { apidae_id: @selection.apidae_id, label: @selection.label, reference: @selection.reference }
      end

      assert_redirected_to selection_path(assigns(:selection))
    end

    test "should show selection" do
      get :show, id: @selection
      assert_response :success
    end

    test "should get edit" do
      get :edit, id: @selection
      assert_response :success
    end

    test "should update selection" do
      patch :update, id: @selection, selection: { apidae_id: @selection.apidae_id, label: @selection.label, reference: @selection.reference }
      assert_redirected_to selection_path(assigns(:selection))
    end

    test "should destroy selection" do
      assert_difference('Selection.count', -1) do
        delete :destroy, id: @selection
      end

      assert_redirected_to selections_path
    end
  end
end
