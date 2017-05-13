class AddTownInseeCodeToObjects < ActiveRecord::Migration
  def change
    add_column :apidae_objects, :town_insee_code, :string
  end
end
