class CreateApidaeAttachedFiles < ActiveRecord::Migration[4.2]
  def change
    create_table :apidae_attached_files do |t|
      t.string :name
      t.string :credits
      t.text :description
      t.integer :apidae_object_id
      if t.respond_to?(:attachment)
        t.attachment :picture
      end

      t.timestamps null: false
    end
  end
end
