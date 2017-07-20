class AddEntityDataToObjects < ActiveRecord::Migration
  def change
    add_column :apidae_objects, :entity_data, :text
  end
end
