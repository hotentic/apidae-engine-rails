class AddApidaeTypeIndexOnReferences < ActiveRecord::Migration[5.2]
  def change
    add_index :apidae_references, :apidae_type
  end
end
