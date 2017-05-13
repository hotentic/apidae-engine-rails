class CreateApidaeAttachedFiles < ActiveRecord::Migration
  def change
    create_table :apidae_attached_files do |t|
      t.string :name
      t.string :credits
      t.text :description
      t.integer :apidae_object_id
      t.attachment :picture

      t.timestamps null: false
    end
  end
end
