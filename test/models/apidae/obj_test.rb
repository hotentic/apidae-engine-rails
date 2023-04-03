require 'test_helper'

module Apidae
  class ObjTest < ActiveSupport::TestCase

    test 'populate empty booking desc' do
      obj = setup_obj('test/data/hot_fr_en.json', [Apidae::LOCALE_FR])

      assert_nil obj.booking_desc
    end

    test 'archive short_desc previous value' do
      obj = setup_obj('test/data/hot_fr_en.json', [Apidae::LOCALE_FR])

      obj.short_desc = 'short desc fr modif'

      assert obj.save
      assert_equal({'fr' => {'prev' => 'short desc fr', 'ts' => Time.current.to_i}}, obj.prev_data['short_desc'])
    end

    test 'archive short_desc localized previous value' do
      obj = setup_obj('test/data/hot_fr_en.json', [Apidae::LOCALE_FR, Apidae::LOCALE_EN])

      obj.set_short_desc('fr' => 'short desc fr modif', 'en' => 'short desc en modif')

      assert obj.save
      assert_equal({
                     'fr' => {'prev' => 'short desc fr', 'ts' => Time.current.to_i},
                     'en' => {'prev' => 'short desc en', 'ts' => Time.current.to_i}
                   }, obj.prev_data['short_desc'])
    end

    test 'archive existing telephone value' do
      obj = setup_obj('test/data/hot_fr_en.json', [Apidae::LOCALE_FR])

      obj.telephone['36504392']['value'] = '01 02 03 04 05'
      obj.save

      assert_equal({'36504392' => { 'prev' => { 'value' => '04 71 49 09 09', 'description' => nil}, 'ts' => Time.current.to_i}}, obj.prev_data['telephone'])
    end

    test 'archive email addition' do
      obj = setup_obj('test/data/hot_fr_en.json', [Apidae::LOCALE_FR])

      obj.email['99999999'] = {'value' => '01 02 03 04 05', 'description' => nil}
      obj.save

      assert_equal({'36504394' => {'prev' => {"value" => "chatelleraie@wanadoo.fr", "description" => nil}, 'ts' => Time.current.to_i}}, obj.prev_data['email'])
    end

    test 'archive address value' do
      obj = setup_obj('test/data/hot_fr_en.json', [Apidae::LOCALE_FR])

      obj.address = ['Test', "Château de La Devèze", nil]
      obj.save

      assert_equal({'prev' => [nil, "Château de La Devèze", nil], 'ts' => Time.current.to_i}, obj.prev_data['address'])
    end

    test 'archive geolocation value' do
      obj = setup_obj('test/data/hot_fr_en.json', [Apidae::LOCALE_FR])

      obj.latitude = 1.2345
      obj.save

      assert_equal({'prev' => 44.715026, 'ts' => Time.current.to_i}, obj.prev_data['latitude'])
    end

    test 'archive previously blank geolocation value' do
      obj = setup_obj('test/data/hot_fr_en.json', [Apidae::LOCALE_FR])
      obj.skip_archiving = true
      obj.update(latitude: nil, longitude: nil)
      obj.skip_archiving = false

      obj.latitude = 1.2345
      obj.longitude = 2.3456
      obj.save

      assert_equal({'prev' => nil, 'ts' => Time.current.to_i}, obj.prev_data['latitude'])
      assert_equal({'prev' => nil, 'ts' => Time.current.to_i}, obj.prev_data['longitude'])
    end

    test 'archive references list update' do
      obj = setup_obj('test/data/hot_fr_en.json', [Apidae::LOCALE_FR])

      obj.services -= [1115]
      obj.equipments += [1059]
      obj.save

      assert_equal({'prev' => [687, 1115, 1172], 'ts' => Time.current.to_i}, obj.prev_data['services'])
      assert_equal({'prev' => [655, 723, 821, 972, 1058, 1064, 1089, 1093, 1106, 1323], 'ts' => Time.current.to_i}, obj.prev_data['equipments'])
    end

    test 'archive contacts list update' do
      obj = setup_obj('test/data/hot_fr_en.json', [Apidae::LOCALE_FR])

      obj.contacts[0]['nom'] = 'test'
      obj.save

      assert_equal({'prev' => [12954222], 'ts' => Time.current.to_i}, obj.prev_data['contacts'])
    end

    test 'archive openings list update' do
      obj = setup_obj('test/data/hot_fr_en.json', [Apidae::LOCALE_FR])

      obj.openings += [{"id" => 123456, "start_date" => "2018-04-01", "end_date" => "2018-10-14"}]
      obj.save

      assert_equal({'prev' => [14375379], 'ts' => Time.current.to_i}, obj.prev_data['openings'])
    end

    test 'archive rates list update' do
      obj = setup_obj('test/data/hot_fr_en.json', [Apidae::LOCALE_FR])

      obj.rates += [{"id" => 123456, "start_date" => "2018-04-01", "end_date" => "2018-10-14"}]
      obj.save

      assert_equal({'prev' => [8605788], 'ts' => Time.current.to_i}, obj.prev_data['rates'])
    end

    test 'archive pictures list update' do
      obj = setup_obj('test/data/hot_fr_en.json', [Apidae::LOCALE_FR])

      obj.pictures.delete_if {|p| p['id'] == 1890699}
      obj.save

      assert_equal({'fr' => {'prev' => [1890696, 1890697, 1890698, 1890699, 1890700, 1890701, 1890702, 1890703, 1890704, 1890705, 1890706], 'ts' => Time.current.to_i}}, obj.prev_data['pictures'])
    end

    test 'archive capacity field update' do
      obj = setup_obj('test/data/hot_fr_en.json', [Apidae::LOCALE_FR])

      obj.capacity['nombreChambresFamiliales'] = 2
      obj.save

      assert_equal({'prev' => 1, 'ts' => Time.current.to_i}, obj.prev_data['capacity']['nombreChambresFamiliales'])
    end

    test 'archive versioned short_desc field update' do
      obj = setup_obj('test/data/cos_winter.json', [Apidae::LOCALE_FR], [Apidae::STANDARD_VERSION, Apidae::WINTER_VERSION])

      obj = obj.in_version(Apidae::WINTER_VERSION)
      obj.short_desc = 'short desc winter fr modif'
      obj.save

      assert_equal({'fr' => {'prev' => 'short desc winter fr', 'ts' => Time.current.to_i}}, obj.prev_data['short_desc'])
    end

    test 'archive versioned localized short_desc field update' do
      obj = setup_obj('test/data/cos_winter.json', [Apidae::LOCALE_FR, Apidae::LOCALE_DE], [Apidae::STANDARD_VERSION, Apidae::WINTER_VERSION])

      obj = obj.in_version(Apidae::WINTER_VERSION).in_locale(Apidae::LOCALE_DE)
      obj.short_desc = 'short desc winter de modif'
      obj.save

      assert_equal({'prev' => 'short desc standard de', 'ts' => Time.current.to_i}, obj.prev_data['short_desc']['de'])
    end

    test 'archive type_data subfield without updating others' do
      obj = setup_obj('test/data/hot_fr_en.json', [Apidae::LOCALE_FR])

      obj.categories -= [1610]
      obj.save

      assert_nil(obj.prev_data['capacity'])
    end

    private

    def setup_obj(json_file, locales, versions = nil)
      objects_json = File.read(json_file)
      obj_data = JSON.parse(objects_json, symbolize_names: true).first

      obj = Apidae::Obj.new
      Apidae::Obj.update_object(obj, obj_data, locales, versions)
      obj.save
      obj
    end
  end
end
