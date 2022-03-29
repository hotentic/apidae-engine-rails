require 'test_helper'

module Apidae
  class ObjTest < ActiveSupport::TestCase

    test "populate empty booking desc" do
      objects_json = File.read('test/data/hot_fr_en.json')
      obj_data = JSON.parse(objects_json, symbolize_names: true).first

      obj = Apidae::Obj.new
      Apidae::Obj.populate_fields(obj, obj_data, [Apidae::LOCALE_FR])

      assert_nil obj.booking_desc
    end
  end
end
