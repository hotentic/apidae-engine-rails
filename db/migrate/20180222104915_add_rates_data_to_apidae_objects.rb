class AddRatesDataToApidaeObjects < ActiveRecord::Migration[5.1]
  def change
    add_column :apidae_objects, :rates_data, :jsonb
    remove_column :apidae_objects, :rates
  end
end
