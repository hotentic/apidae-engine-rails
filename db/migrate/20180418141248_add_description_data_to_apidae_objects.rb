class AddDescriptionDataToApidaeObjects < ActiveRecord::Migration[5.1]
  def change
    add_column :apidae_objects, :description_data, :jsonb
  end
end
