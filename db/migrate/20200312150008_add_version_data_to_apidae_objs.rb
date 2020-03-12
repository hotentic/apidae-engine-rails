class AddVersionDataToApidaeObjs < ActiveRecord::Migration[5.2]
  def change
    add_column :apidae_objs, :version_data, :jsonb
  end
end
