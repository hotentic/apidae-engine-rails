class RenameObjectsToObj < ActiveRecord::Migration[5.1]
  def change
    rename_table :apidae_objects, :apidae_objs
  end
end
