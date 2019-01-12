class AddApidaeIdToApidaeFileImports < ActiveRecord::Migration[5.1]
  def change
    add_column :apidae_file_imports, :apidae_id, :integer
  end
end
