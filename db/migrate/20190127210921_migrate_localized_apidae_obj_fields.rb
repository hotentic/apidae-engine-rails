class MigrateLocalizedApidaeObjFields < ActiveRecord::Migration[5.2]
  def change
    Apidae::Obj.all.each do |o|
      o.set_short_desc({'fr' => o.description_data['short_desc']}) unless (o.description_data.blank? || !o.description_data.has_key?('short_desc') || o.description_data['short_desc'].is_a?(Hash))
      o.set_long_desc({'fr' => o.description_data['long_desc']}) unless (o.description_data.blank? || !o.description_data.has_key?('long_desc') || o.description_data['long_desc'].is_a?(Hash))
      o.theme_desc = {'fr' => o.description_data['theme_desc']} unless (o.description_data.blank? || !o.description_data.has_key?('theme_desc') || o.description_data['theme_desc'].is_a?(Hash))
      o.private_desc = {'fr' => o.description_data['private_desc']} unless (o.description_data.blank? || !o.description_data.has_key?('private_desc') || o.description_data['private_desc'].is_a?(Hash))
      o.set_pictures({'fr' => o.pictures_data['pictures']}) unless (o.pictures_data.blank? || !o.pictures_data.has_key?('pictures') || o.pictures_data['pictures'].is_a?(Hash))
      o.set_attachments({'fr' => o.attachments_data['attachments']}) unless (o.attachments_data.blank? || !o.attachments_data.has_key?('attachments') || o.attachments_data['attachments'].is_a?(Hash))
      o.set_openings_desc({'fr' => o.openings_data['openings_desc']}) unless (o.openings_data.blank? || !o.openings_data.has_key?('openings_desc') || o.openings_data['openings_desc'].is_a?(Hash))
      o.set_rates_desc({'fr' => o.rates_data['rates_desc']}) unless (o.rates_data.blank? || !o.rates_data.has_key?('rates_desc') || o.rates_data['rates_desc'].is_a?(Hash))
      o.set_includes({'fr' => o.rates_data['includes']}) unless (o.rates_data.blank? || !o.rates_data.has_key?('includes') || o.rates_data['includes'].is_a?(Hash))
      o.set_excludes({'fr' => o.rates_data['excludes']}) unless (o.rates_data.blank? || !o.rates_data.has_key?('excludes') || o.rates_data['excludes'].is_a?(Hash))
      o.set_extra({'fr' => o.type_data['extra']}) unless (o.type_data.blank? || !o.type_data.has_key?('extra') || o.type_data['extra'].is_a?(Hash))
      o.save!
    end
  end
end
