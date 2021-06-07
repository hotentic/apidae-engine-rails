class AddApidaeTypeToApidaeTerritories < ActiveRecord::Migration[6.1]
  def change
    add_column :apidae_territories, :apidae_type, :integer
  end
end
