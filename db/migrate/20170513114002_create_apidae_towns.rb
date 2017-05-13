class CreateApidaeTowns < ActiveRecord::Migration
  def change
    create_table :apidae_towns do |t|
      t.string :country
      t.integer :apidae_id
      t.string :insee_code
      t.string :name
      t.string :postal_code

      t.timestamps null: false

      t.index :insee_code, unique: true
    end
  end
end
