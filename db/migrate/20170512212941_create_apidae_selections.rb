class CreateApidaeSelections < ActiveRecord::Migration[4.2]
  def change
    create_table :apidae_selections do |t|
      t.string :label
      t.string :reference
      t.integer :apidae_id

      t.timestamps null: false
    end
  end
end
