class RemoveLatLngFromApidaeObjects < ActiveRecord::Migration[5.1]
  def change
    remove_column :apidae_objects, :latitude
    remove_column :apidae_objects, :longitude
  end
end
