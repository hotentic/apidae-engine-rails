class RemoveDescColumnsFromApidaeObjects < ActiveRecord::Migration[5.1]
  def change
    remove_column :apidae_objects, :short_desc
    remove_column :apidae_objects, :long_desc
  end
end
