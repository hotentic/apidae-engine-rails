class AddServiceDataToApidaeObjects < ActiveRecord::Migration[5.1]
  def change
    add_column :apidae_objects, :service_data, :jsonb
  end
end
