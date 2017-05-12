class CreateApidaeObjects < ActiveRecord::Migration
  def change
    create_table :apidae_objects do |t|
      t.string :address
      t.integer :apidae_id
      t.string :apidae_type
      t.string :apidae_subtype
      t.string :title
      t.text :short_desc
      t.text :contact
      t.text :long_desc
      t.text :type_data
      t.float :latitude
      t.float :longitude
      t.text :openings
      t.text :rates
      t.text :reservation

      t.timestamps null: false
    end
  end
end
