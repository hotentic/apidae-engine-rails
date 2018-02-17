class CreateApidaeFileImports < ActiveRecord::Migration[4.2]
  def change
    create_table :apidae_file_imports do |t|
      t.string :status
      t.string :remote_file
      t.integer :created
      t.integer :updated
      t.integer :deleted

      t.timestamps null: false
    end
  end
end
