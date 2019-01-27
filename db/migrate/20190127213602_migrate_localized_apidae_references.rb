class MigrateLocalizedApidaeReferences < ActiveRecord::Migration[5.2]
  def change
    Apidae::Reference.all.each do |ref|
      ref.label_data = {'fr' => ref.label_data['libelleFr']} unless ref.label_data.blank? || ref.label_data['libelleFr'].blank?
      ref.save!
    end
  end
end
