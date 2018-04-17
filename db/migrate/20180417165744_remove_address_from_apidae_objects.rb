class RemoveAddressFromApidaeObjects < ActiveRecord::Migration[5.1]
  def change
    remove_column :apidae_objects, :address
  end
end
