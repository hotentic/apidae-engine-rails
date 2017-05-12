require 'test_helper'

module Apidae
  class ObjectsControllerTest < ActionController::TestCase
    setup do
      @object = apidae_objects(:one)
      @routes = Engine.routes
    end

    test "should get index" do
      get :index
      assert_response :success
      assert_not_nil assigns(:objects)
    end

    test "should get new" do
      get :new
      assert_response :success
    end

    test "should create object" do
      assert_difference('Object.count') do
        post :create, object: { address: @object.address, apidae_id: @object.apidae_id, apidae_subtype: @object.apidae_subtype, apidae_type: @object.apidae_type, contact: @object.contact, latitude: @object.latitude, long_desc: @object.long_desc, longitude: @object.longitude, openings: @object.openings, rates: @object.rates, reservation: @object.reservation, short_desc: @object.short_desc, title: @object.title, type_data: @object.type_data }
      end

      assert_redirected_to object_path(assigns(:object))
    end

    test "should show object" do
      get :show, id: @object
      assert_response :success
    end

    test "should get edit" do
      get :edit, id: @object
      assert_response :success
    end

    test "should update object" do
      patch :update, id: @object, object: { address: @object.address, apidae_id: @object.apidae_id, apidae_subtype: @object.apidae_subtype, apidae_type: @object.apidae_type, contact: @object.contact, latitude: @object.latitude, long_desc: @object.long_desc, longitude: @object.longitude, openings: @object.openings, rates: @object.rates, reservation: @object.reservation, short_desc: @object.short_desc, title: @object.title, type_data: @object.type_data }
      assert_redirected_to object_path(assigns(:object))
    end

    test "should destroy object" do
      assert_difference('Object.count', -1) do
        delete :destroy, id: @object
      end

      assert_redirected_to objects_path
    end
  end
end
