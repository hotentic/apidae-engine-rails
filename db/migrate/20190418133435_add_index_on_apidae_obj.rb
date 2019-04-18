class AddIndexOnApidaeObj < ActiveRecord::Migration[5.2]
  def change
    add_index :apidae_objs, :apidae_id, unique: false, name: 'apidae_objs_apidae_id'
    add_index :apidae_objs, :root_obj_id, unique: false, name: 'apidae_objs_root_obj_id'
  end
end
