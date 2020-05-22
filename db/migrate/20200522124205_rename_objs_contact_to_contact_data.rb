class RenameObjsContactToContactData < ActiveRecord::Migration[5.2]
  def change
    rename_column :apidae_objs, :contact, :contact_data
  end
end
