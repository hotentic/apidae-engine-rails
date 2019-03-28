module Apidae
  class Town < ActiveRecord::Base
    def self.import(towns_json)
      towns_hashes = JSON.parse(towns_json, symbolize_names: true)
      if towns_hashes.length != count
        countries = Hash[Reference.where(apidae_type: "Pays").map {|ref| [ref.apidae_id, ref.label(:fr)]}]
        towns_hashes.each do |town_data|
          town = Town.find_or_initialize_by(apidae_id: town_data[:id])
          town.name = town_data[:nom]
          town.postal_code = town_data[:codePostal]
          town.insee_code = town_data[:code]
          town.country = countries[town_data[:pays][:id]]
          town.description = town_data[:complement]
          town.save!
        end
      end
    end

    def self.import_file(json_file)
      towns_json = File.read(json_file)
      import(towns_json)
    end

    def label
      "#{name} (#{postal_code})"
    end
  end
end
