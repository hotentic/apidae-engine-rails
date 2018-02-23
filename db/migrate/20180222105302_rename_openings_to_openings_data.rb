class RenameOpeningsToOpeningsData < ActiveRecord::Migration[5.1]
  def change
    rename_column :apidae_objects, :openings, :openings_data
  end
end
