class AddApidaeTownIdToApidaeObjs < ActiveRecord::Migration[6.1]
  def change
    add_column :apidae_objs, :apidae_town_id, :integer
    add_index :apidae_objs, :apidae_town_id
  end
end
