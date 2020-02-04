class AddLastUpdateToApidaeOjbs < ActiveRecord::Migration[5.2]
  def change
    add_column :apidae_objs, :last_update, :datetime
  end
end
