class AddOwnerDataToApidaeObjs < ActiveRecord::Migration[5.2]
  def change
    add_column :apidae_objs, :owner_data, :jsonb
  end
end
