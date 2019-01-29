class UpgradeApidaeObjsTitleDataType < ActiveRecord::Migration[5.2]
  def change
    add_column :apidae_objs, :title_data, :jsonb
    Apidae::Obj.all.unscoped.each do |o|
      o.update(title_data: {'title' => {'fr' => o.read_attribute(:title)}})
    end
    remove_column :apidae_objs, :title
  end
end
