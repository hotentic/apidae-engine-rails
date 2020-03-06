class AddTownInseeCodeIndexToObjs < ActiveRecord::Migration[5.2]
  def change
    add_index :apidae_objs, :town_insee_code
  end
end
