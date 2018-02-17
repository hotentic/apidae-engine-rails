class AddPicturesDataToObjects < ActiveRecord::Migration[4.2]
  def change
    add_column :apidae_objects, :pictures_data, :text
  end
end
