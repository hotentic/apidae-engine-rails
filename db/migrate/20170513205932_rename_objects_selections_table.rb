class RenameObjectsSelectionsTable < ActiveRecord::Migration
  def change
    rename_table :apidae_objects_apidae_selections, :apidae_objects_selections
  end
end
