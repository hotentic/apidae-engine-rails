class AddMetaDataToApidaeObjects < ActiveRecord::Migration[5.1]
  def change
    add_column :apidae_objects, :meta_data, :jsonb
  end
end
