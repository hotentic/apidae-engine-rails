class AddVersionToApidaeObjs < ActiveRecord::Migration[5.2]
  def change
    add_column :apidae_objs, :version, :string
    add_column :apidae_objs, :root_obj_id, :integer
    add_column :apidae_projects, :versions_data, :string

    Apidae::Obj.update_all(version: Apidae::DEFAULT_VERSION)
  end
end
