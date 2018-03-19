class RemoveApidaeIdUnicity < ActiveRecord::Migration[5.1]
  def change
    remove_index :apidae_references, :apidae_id
    add_index :apidae_references, :apidae_id
  end
end
