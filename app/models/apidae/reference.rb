module Apidae
  class Reference < ApplicationRecord

    INTERNAL = 'internal'

    store_accessor :meta_data, :category, :parent

    def self.default_scope
      where(is_active: true)
    end

    def self.import(refs_json)
      locales = Rails.application.config.respond_to?(:apidae_locales) ? Rails.application.config.apidae_locales : [DEFAULT_LOCALE]
      locales_map = Hash[locales.map {|loc| ["libelle#{loc.camelize.gsub('-', '')}".to_sym, loc]}]
      refs_hashes = JSON.parse(refs_json, symbolize_names: true)
      if refs_hashes.length != where("apidae_type != ?", INTERNAL).count
        refs_hashes.each do |ref_data|
          ref = Reference.find_or_initialize_by(apidae_id: ref_data[:id], apidae_type: ref_data[:elementReferenceType])
          ref.label_data = ref_data.slice(*locales_map.keys).transform_keys {|k| locales_map[k]}
          ref.parent = ref_data[:parent][:id] if ref_data[:parent]
          ref.category = ref_data[:familleCritere] ? ref_data[:familleCritere][:id] : (ref_data[:typeLabel] ? ref_data[:typeLabel][:id] : nil)
          ref.is_active = ref_data[:actif]
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
      label_data[language.to_s]
    end

    def detailed_label(language)
      category ? "#{Reference.find_by_apidae_id(category).label(language)} - #{label(language)}" : label(language)
    end
  end
end
