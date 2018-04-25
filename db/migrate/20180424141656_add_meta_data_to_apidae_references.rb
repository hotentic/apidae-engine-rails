class AddMetaDataToApidaeReferences < ActiveRecord::Migration[5.1]
  def change
    add_column :apidae_references, :meta_data, :jsonb
  end
end
