class MigrateLocalizedApidaeObjFields < ActiveRecord::Migration[5.2]
  def change
    Apidae::Obj.all.each do |o|
      o.short_desc = {'fr' => o.description_data['short_desc']} unless (o.description_data.blank? || o.description_data['short_desc'].blank? || o.description_data['short_desc'].is_a?(Hash))
      o.long_desc = {'fr' => o.description_data['long_desc']} unless (o.description_data.blank? || o.description_data['long_desc'].blank? || o.description_data['long_desc'].is_a?(Hash))
      o.theme_desc = {'fr' => o.description_data['theme_desc']} unless (o.description_data.blank? || o.description_data['theme_desc'].blank? || o.description_data['theme_desc'].is_a?(Hash))
      o.private_desc = {'fr' => o.description_data['private_desc']} unless (o.description_data.blank? || o.description_data['private_desc'].blank? || o.description_data['private_desc'].is_a?(Hash))
      o.pictures = {'fr' => o.pictures_data['pictures']} unless (o.pictures_data.blank? || o.pictures_data['pictures'].blank? || o.pictures_data['pictures'].is_a?(Hash))
      o.attachments = {'fr' => o.attachments_data['attachments']} unless (o.attachments_data.blank? || o.attachments_data['attachments'].blank? || o.attachments_data['attachments'].is_a?(Hash))
      o.openings_desc = {'fr' => o.openings_data['openings_desc']} unless (o.openings_data.blank? || o.openings_data['openings_desc'].blank? || o.openings_data['openings_desc'].is_a?(Hash))
      o.rates_desc = {'fr' => o.rates_data['rates_desc']} unless (o.rates_data.blank? || o.rates_data['rates_desc'].blank? || o.rates_data['rates_desc'].is_a?(Hash))
      o.includes = {'fr' => o.rates_data['includes']} unless (o.rates_data.blank? || o.rates_data['includes'].blank? || o.rates_data['includes'].is_a?(Hash))
      o.excludes = {'fr' => o.rates_data['excludes']} unless (o.rates_data.blank? || o.rates_data['excludes'].blank? || o.rates_data['excludes'].is_a?(Hash))
      o.extra = {'fr' => o.type_data['extra']} unless (o.type_data.blank? || o.type_data['extra'].blank? || o.type_data['extra'].is_a?(Hash))
      o.save!
    end
  end
end
