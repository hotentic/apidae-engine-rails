class AddEntityDataToObjects < ActiveRecord::Migration[4.2]
  def change
    add_column :apidae_objects, :entity_data, :text
  end
end
