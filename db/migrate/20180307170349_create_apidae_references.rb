class CreateApidaeReferences < ActiveRecord::Migration[5.1]
  def change
    create_table :apidae_references do |t|
      t.integer :apidae_id
      t.string :apidae_type
      t.jsonb :label_data
      t.index :apidae_id, unique: true

      t.timestamps
    end
  end
end
