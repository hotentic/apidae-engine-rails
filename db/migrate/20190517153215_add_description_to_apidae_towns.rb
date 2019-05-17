class AddDescriptionToApidaeTowns < ActiveRecord::Migration[5.2]
  def change
    add_column :apidae_towns, :description, :string
  end
end
