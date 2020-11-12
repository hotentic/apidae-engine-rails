class CreateApidaeTerritories < ActiveRecord::Migration[6.0]
  def change
    create_table :apidae_territories do |t|
      t.integer :apidae_id
      t.string :name
    end

    add_index :apidae_territories, :apidae_id
  end
end
