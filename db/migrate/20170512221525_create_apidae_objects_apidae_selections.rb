class CreateApidaeObjectsApidaeSelections < ActiveRecord::Migration
  def change
    create_table :apidae_objects_apidae_selections do |t|
      t.integer :object_id
      t.integer :selection_id
    end
  end
end
