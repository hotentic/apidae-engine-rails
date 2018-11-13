class AddProjectIdToSelections < ActiveRecord::Migration[5.1]
  def change
    add_column :apidae_selections, :apidae_project_id, :integer
  end
end
