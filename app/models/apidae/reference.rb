module Apidae
  class Reference < ApplicationRecord
    def self.import(refs_json)
      refs_hashes = JSON.parse(refs_json, symbolize_names: true)
      if refs_hashes.length != count
        refs_hashes.each do |ref_data|
          ref = Reference.find_or_initialize_by(apidae_id: ref_data[:id])
          ref.apidae_type = ref_data[:elementReferenceType]
          ref.label_data = ref_data.slice(:libelleFr, :libelleEn)
          ref.save!
        end
      end
    end

    def self.import_file(json_file)
      refs_json = File.read(json_file)
      import(refs_json)
    end

    def label(language)
      label_data["libelle#{language.to_s.upcase_first}"]
    end
  end
end
