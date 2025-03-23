class ChangeObjCertificationsStructure < ActiveRecord::Migration[7.2]
  def change
    blank_objs = Apidae::Obj.where("type_data->'certifications'->0->>'id' IS NULL")
    set_objs = Apidae::Obj.where("type_data->'certifications'->0->>'id' IS NOT NULL")

    blank_objs.update_all("type_data = jsonb_set(type_data, '{certifications}', '{}'::jsonb)")

    set_objs.each do |o|
      unless o.certifications.is_a?(Hash)
        o.certifications = o.certifications.blank? ? {} : Hash[o.certifications.map {|c| [c['id'].to_s, c['identifier']]}]
        o.save!
      end
    end
  end
end
