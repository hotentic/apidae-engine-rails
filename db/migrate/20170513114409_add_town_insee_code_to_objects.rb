class AddTownInseeCodeToObjects < ActiveRecord::Migration[4.2]
  def change
    add_column :apidae_objects, :town_insee_code, :string
  end
end
