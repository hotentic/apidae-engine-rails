class ChangeTextColumnsToJson < ActiveRecord::Migration[5.1]
  def change
    change_column :apidae_objects, :pictures_data, :jsonb, using: 'pictures_data::text::jsonb'
    change_column :apidae_objects, :type_data, :jsonb, using: 'type_data::text::jsonb'
    change_column :apidae_objects, :entity_data, :jsonb, using: 'entity_data::text::jsonb'
    change_column :apidae_objects, :contact, :jsonb, using: 'contact::text::jsonb'
    change_column :apidae_objects, :address, :jsonb, using: 'address::text::jsonb'
    change_column :apidae_objects, :openings, :jsonb, using: 'openings::text::jsonb'
  end
end
