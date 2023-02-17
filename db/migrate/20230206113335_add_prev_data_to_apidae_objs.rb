class AddPrevDataToApidaeObjs < ActiveRecord::Migration[6.1]
  def change
    add_column :apidae_objs, :prev_data, :jsonb
  end
end
