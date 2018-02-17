class CreateApidaeExports < ActiveRecord::Migration[4.2]
  def change
    create_table :apidae_exports do |t|
      t.string :status
      t.string :remote_status
      t.boolean :oneshot
      t.boolean :reset
      t.string :file_url
      t.string :confirm_url
      t.integer :project_id

      t.timestamps null: false
    end
  end
end
