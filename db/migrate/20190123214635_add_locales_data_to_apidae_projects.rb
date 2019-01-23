class AddLocalesDataToApidaeProjects < ActiveRecord::Migration[5.2]
  def change
    add_column :apidae_projects, :locales_data, :string
  end
end
