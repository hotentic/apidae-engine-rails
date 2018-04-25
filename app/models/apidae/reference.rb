module Apidae
  class Reference < ApplicationRecord

    INTERNAL = 'internal'

    store_accessor :meta_data, :category, :parent

    def self.import(refs_json)
      refs_hashes = JSON.parse(refs_json, symbolize_names: true)
      if refs_hashes.length != where("apidae_type != ?", INTERNAL).count
        refs_hashes.each do |ref_data|
          ref = Reference.find_or_initialize_by(apidae_id: ref_data[:id], apidae_type: ref_data[:elementReferenceType])
          ref.label_data = ref_data.slice(:libelleFr, :libelleEn)
          ref.parent = ref_data[:parent][:id] if ref_data[:parent]
          ref.category = ref_data[:familleCritere] ? ref_data[:familleCritere][:id] : (ref_data[:typeLabel] ? ref_data[:typeLabel][:id] : nil)
          ref.save!
        end
      end
    end

    def self.import_file(json_file)
      refs_json = File.read(json_file)
      import(refs_json)
    end

    def self.import_internal(internal_json)
      refs_hashes = JSON.parse(internal_json, symbolize_names: true)
      if refs_hashes.length != where(apidae_type: INTERNAL).count
        refs_hashes.each do |ref_data|
          ref = Reference.find_or_initialize_by(apidae_id: ref_data[:id], apidae_type: INTERNAL)
          ref.label_data = {libelleFr: ref_data[:libelle]}
          ref.save!
        end
      end
    end

    def label(language)
      label_data["libelle#{language.to_s.upcase_first}"]
    end

    def detailed_label(language)
      category ? "#{Apidae::Reference.find_by_apidae_id(category).label(language)} - #{label(language)}" : label(language)
    end
  end
end
