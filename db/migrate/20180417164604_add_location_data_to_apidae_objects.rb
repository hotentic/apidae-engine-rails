class AddLocationDataToApidaeObjects < ActiveRecord::Migration[5.1]
  def change
    add_column :apidae_objects, :location_data, :jsonb
  end
end
