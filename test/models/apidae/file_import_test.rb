require 'test_helper'

module Apidae
  class FileImportTest < ActiveSupport::TestCase
    setup do
      Apidae::Object.delete_all
      Apidae::Selection.delete_all
      @result = {created: 0, updated: 0, deleted: 0, selections: []}
    end

    test "new object insertion" do
      objects_json = File.read('test/data/structure.json')
      FileImport.add_or_update_objects(objects_json, @result)
      assert_equal 1, Apidae::Object.count
      new_obj = Apidae::Object.first
      assert_equal 504, new_obj.apidae_id
      assert_equal({created: 1, updated: 0, deleted: 0, selections: []}, @result)
    end

    test "existing object update" do
      Apidae::Object.create(apidae_id: 504, title: 'Société des contrebassistes aixois')
      objects_json = File.read('test/data/structure.json')
      FileImport.add_or_update_objects(objects_json, @result)
      assert_equal 1, Apidae::Object.count
      updated_obj = Apidae::Object.first
      assert_equal 504, updated_obj.apidae_id
      assert_equal 'Société des accordéonistes aixois', updated_obj.title
      assert_equal({created: 0, updated: 1, deleted: 0, selections: []}, @result)
    end

    test "existing object deletion" do
      Apidae::Object.create(apidae_id: 504, title: 'Société des contrebassistes aixois')
      objects_json = File.read('test/data/deletion.json')
      FileImport.delete_objects(objects_json, @result)
      assert_equal 0, Apidae::Object.count
      assert_equal({created: 0, updated: 0, deleted: 1, selections: []}, @result)
    end

    test "new selection insertion" do
      Apidae::Object.create(apidae_id: 504, title: 'Société des contrebassistes aixois')
      objects_json = File.read('test/data/selections.json')
      FileImport.add_or_update_selections(objects_json, @result)
      assert_equal 1, Apidae::Selection.count
      new_sel = Apidae::Selection.first
      assert_equal 49063, new_sel.apidae_id
      assert_equal 'Sélection 1', new_sel.label
      assert_equal 'selection-1', new_sel.reference
      assert_equal({created: 0, updated: 0, deleted: 0,
                    selections: [{apidae_id: 49063, reference: 'selection-1', objects: 1}]}, @result)
    end

    test "existing selection update" do
      obj = Apidae::Object.create(apidae_id: 503, title: 'Société des contrebassistes aixois')
      Apidae::Object.create(apidae_id: 504, title: 'Société des contrebassistes aixois')
      sel = Apidae::Selection.create(apidae_id: 49063, label: 'Sélection 2', reference: 'selection-2')
      sel.objects << obj
      assert_equal 1, sel.objects.count
      objects_json = File.read('test/data/update_selections.json')
      FileImport.add_or_update_selections(objects_json, @result)
      assert_equal 1, Apidae::Selection.count
      assert_equal 49063, sel.apidae_id
      assert_equal 'Sélection 2', sel.label
      assert_equal 'selection-2', sel.reference
      assert_equal({created: 0, updated: 0, deleted: 0,
                    selections: [{apidae_id: 49063, reference: 'selection-2', objects: 2}]}, @result)
    end

    test "existing selection deletion" do
      Apidae::Selection.create(apidae_id: 49063, label: 'Sélection 3', reference: 'selection-3')
      objects_json = File.read('test/data/delete_selections.json')
      assert_equal 1, Apidae::Selection.count
      FileImport.add_or_update_selections(objects_json, @result)
      assert_equal 0, Apidae::Selection.count
    end

    test "full import process" do
      Apidae::Object.create(apidae_id: 123, title: 'Objet à supprimer')
      Apidae::Object.create(apidae_id: 4826186, title: 'Objet à mettre à jour')
      result = FileImport.import('test/data/json_export.zip')
      assert_equal 2, Apidae::Selection.all.count
      assert_equal 5, Apidae::Object.all.count
      assert_equal({created: 4, updated: 1, deleted: 1, selections: [
          {apidae_id: 49063, reference: 'selection-1', objects: 2},
          {apidae_id: 49073, reference: 'selection-2', objects: 3}
      ]}, result)
    end
   end
end
