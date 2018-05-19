class RemoveInseeCodeUnicity < ActiveRecord::Migration[5.1]
  # Removed because insee_code isnt unique for foreign towns
  def change
    remove_index :apidae_towns, :insee_code
    add_index :apidae_towns, :insee_code
  end
end
