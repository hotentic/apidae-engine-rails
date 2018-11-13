class CreateApidaeProjects < ActiveRecord::Migration[5.1]
  def change
    create_table :apidae_projects do |t|
      t.string :name
      t.integer :apidae_id
      t.string :api_key
      t.timestamps
    end
  end
end
