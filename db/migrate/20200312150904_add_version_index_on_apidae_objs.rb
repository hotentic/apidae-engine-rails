class AddVersionIndexOnApidaeObjs < ActiveRecord::Migration[5.2]
  def change
    add_index :apidae_objs, [:root_obj_id, :version], unique: true
  end
end
