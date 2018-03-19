module Apidae
  class Reference < ApplicationRecord

    INTERNAL = 'internal'

    def self.import(refs_json)
      refs_hashes = JSON.parse(refs_json, symbolize_names: true)
      if refs_hashes.length != where("apidae_type != ?", INTERNAL).count
        refs_hashes.each do |ref_data|
          ref = Reference.find_or_initialize_by(apidae_id: ref_data[:id], apidae_type: ref_data[:elementReferenceType])
          ref.label_data = ref_data.slice(:libelleFr, :libelleEn)
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
  end
end
