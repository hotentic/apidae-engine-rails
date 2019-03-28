class AddDescriptionToApidaeTowns < ActiveRecord::Migration[5.1]
  def change
    add_column :apidae_towns, :description, :string
  end
end
