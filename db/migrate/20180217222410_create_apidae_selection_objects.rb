class CreateApidaeSelectionObjects < ActiveRecord::Migration[5.1]
  def change
    create_table :apidae_selection_objects do |t|
      t.integer :apidae_selection_id
      t.integer :apidae_object_id

      t.timestamps
    end
  end
end
