class AddPicturesDataToObjects < ActiveRecord::Migration
  def change
    add_column :apidae_objects, :pictures_data, :text
  end
end
