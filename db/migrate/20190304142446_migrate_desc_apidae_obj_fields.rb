class MigrateDescApidaeObjFields < ActiveRecord::Migration[5.2]
  def change
    Apidae::Obj.all.select(:id, :root_obj_id, :description_data).each do |o|
      ['theme_desc', 'private_desc'].each do |desc_field|
        if !o.description_data.blank? && !o.description_data[desc_field].blank? && o.description_data[desc_field].is_a?(Hash) &&
            o.description_data[desc_field].values[0].is_a?(String)
          o.description_data[desc_field].each_pair do |th, val|
            o.description_data[desc_field][th] = {'fr' => val}
          end
        end
      end
      o.save!
    end
  end
end
