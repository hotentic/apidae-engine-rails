require 'test_helper'

module Apidae
  class FileImportTest < ActiveSupport::TestCase
    setup do
      Obj.delete_all
      Project.delete_all
      Selection.delete_all
      @result = {created: 0, updated: 0, deleted: 0, selections: []}
    end

    test "new object insertion" do
      objects_json = File.read('test/data/structure.json')
      FileImport.add_or_update_objects(objects_json, @result, [], [])
      assert_equal 1, Obj.count
      new_obj = Obj.first
      assert_equal 504, new_obj.apidae_id
      assert_equal({created: 1, updated: 0, deleted: 0, selections: []}, @result)
    end

    test "new object insertion with locales" do
      objects_json = File.read('test/data/hot_fr_en.json')
      FileImport.add_or_update_objects(objects_json, @result, [LOCALE_FR, LOCALE_EN], [])
      assert_equal 1, Obj.count
      new_obj = Obj.first
      assert_equal 898922, new_obj.apidae_id
      assert_equal({created: 1, updated: 0, deleted: 0, selections: []}, @result)
      assert_equal 'short desc fr', new_obj.short_desc
      assert_equal 'long desc fr', new_obj.long_desc
      new_obj.locale = 'en'
      assert_equal 'short desc en', new_obj.short_desc
      assert_equal 'long desc en', new_obj.long_desc
    end

    test "new object insertion with versions" do
      objects_json = File.read('test/data/cos_winter.json')
      FileImport.add_or_update_objects(objects_json, @result, [], [WINTER_VERSION])
      assert_equal 1, Obj.count
      assert_equal 2, Obj.unscoped.count
      root_obj = Obj.find_by_apidae_id(4838849)
      assert_equal 4838849, root_obj.apidae_id
      winter_obj = root_obj.in_version(WINTER_VERSION)
      assert_equal 4838849, winter_obj.apidae_id
      assert_equal root_obj.id, winter_obj.root_obj.id
      assert_equal({created: 1, updated: 0, deleted: 0, selections: []}, @result)
      assert_equal 'short desc standard fr', root_obj.short_desc
      root_obj.obj_version = WINTER_VERSION
      assert_equal 'short desc winter fr', root_obj.short_desc
    end

    test "new object insertion with versions and locales" do
      objects_json = File.read('test/data/cos_winter.json')
      FileImport.add_or_update_objects(objects_json, @result, [LOCALE_FR, LOCALE_EN, LOCALE_DE], [WINTER_VERSION])
      assert_equal 1, Obj.count
      assert_equal 2, Obj.unscoped.count
      root_obj = Obj.find_by_apidae_id(4838849)
      assert_equal 4838849, root_obj.apidae_id
      winter_obj = root_obj.in_version(WINTER_VERSION)
      assert_equal 4838849, winter_obj.apidae_id
      assert_equal root_obj.id, winter_obj.root_obj.id
      assert_equal({created: 1, updated: 0, deleted: 0, selections: []}, @result)
      assert_equal 'short desc standard fr', root_obj.short_desc
      assert_equal 'short desc standard en', root_obj.in_locale(LOCALE_EN).short_desc
      assert_equal 'short desc standard de', root_obj.in_locale(LOCALE_DE).short_desc
      root_obj.obj_version = WINTER_VERSION
      assert_equal 'short desc winter fr', root_obj.in_locale(LOCALE_FR).short_desc
      assert_equal 'short desc standard en', root_obj.in_locale(LOCALE_EN).short_desc
      assert_equal 'short desc standard de', root_obj.in_locale(LOCALE_DE).short_desc
    end

    test "existing object update" do
      Obj.create(apidae_id: 504, title: 'Société des contrebassistes aixois')
      objects_json = File.read('test/data/structure.json')
      FileImport.add_or_update_objects(objects_json, @result, [], [])
      assert_equal 1, Obj.count
      updated_obj = Obj.first
      assert_equal 504, updated_obj.apidae_id
      assert_equal 'Société des accordéonistes aixois', updated_obj.title
      assert_equal({created: 0, updated: 1, deleted: 0, selections: []}, @result)
    end

    test "existing object deletion" do
      Obj.create(apidae_id: 504, title: 'Société des contrebassistes aixois')
      objects_json = File.read('test/data/deletion.json')
      FileImport.delete_objects(objects_json, @result)
      assert_equal 0, Obj.count
      assert_equal({created: 0, updated: 0, deleted: 1, selections: []}, @result)
    end

    test "new selection insertion" do
      Obj.create(apidae_id: 504, title: 'Société des contrebassistes aixois')
      objects_json = File.read('test/data/selections.json')
      proj = Project.create(apidae_id: 123)
      FileImport.add_or_update_selections(proj, objects_json, @result)
      assert_equal 1, Selection.count
      new_sel = Selection.first
      assert_equal 49063, new_sel.apidae_id
      assert_equal 'Sélection 1', new_sel.label
      assert_equal 'selection-1', new_sel.reference
      assert_equal proj.id, new_sel.apidae_project_id
      assert_equal({created: 0, updated: 0, deleted: 0,
                    selections: [{apidae_id: 49063, reference: 'selection-1', objects: 1}]}, @result)
    end

    test "existing selection update" do
      obj = Obj.create(apidae_id: 503, title: 'Société des contrebassistes aixois')
      Obj.create(apidae_id: 504, title: 'Société des contrebassistes aixois')
      proj = Project.create(apidae_id: 123)
      sel = Selection.create(apidae_id: 49063, apidae_project_id: proj.id, label: 'Sélection 2', reference: 'selection-2')
      sel.objects << obj
      assert_equal 1, sel.objects.count
      objects_json = File.read('test/data/update_selections.json')
      FileImport.add_or_update_selections(proj, objects_json, @result)
      assert_equal 1, Selection.count
      assert_equal 49063, sel.apidae_id
      assert_equal 'Sélection 2', sel.label
      assert_equal 'selection-2', sel.reference
      assert_equal proj.id, sel.apidae_project_id
      assert_equal({created: 0, updated: 0, deleted: 0,
                    selections: [{apidae_id: 49063, reference: 'selection-2', objects: 2}]}, @result)
    end

    test "existing selection deletion" do
      proj = Project.create(apidae_id: 123)
      Selection.create(apidae_id: 49063, apidae_project_id: proj.id, label: 'Sélection 3', reference: 'selection-3')
      objects_json = File.read('test/data/delete_selections.json')
      assert_equal 1, Selection.count
      FileImport.add_or_update_selections(proj, objects_json, @result)
      assert_equal 0, Selection.count
    end

    test "full import process" do
      Obj.create(apidae_id: 123, title: 'Objet à supprimer')
      Obj.create(apidae_id: 4826186, title: 'Objet à mettre à jour')
      result = FileImport.import('test/data/json_export.zip', 123)
      assert_equal 1, Project.count
      assert_equal 2, Selection.count
      assert_equal 5, Obj.count
      assert_equal({created: 4, updated: 1, deleted: 1, selections: [
          {apidae_id: 49063, reference: 'selection-1', objects: 2},
          {apidae_id: 49073, reference: 'selection-2', objects: 3}
      ]}, result)
    end
   end
end
