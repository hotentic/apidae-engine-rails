class DestroyAttachedFiles < ActiveRecord::Migration[5.1]
  def change
    drop_table :apidae_attached_files
  end
end
