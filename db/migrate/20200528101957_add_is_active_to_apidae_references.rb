class AddIsActiveToApidaeReferences < ActiveRecord::Migration[5.2]
  def change
    add_column :apidae_references, :is_active, :boolean
    add_index :apidae_references, :is_active, unique: false
  end
end
