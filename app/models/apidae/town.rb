module Apidae
  class Town < ActiveRecord::Base
    def self.import(json_file)
      result = true
      towns_json = File.read(json_file)
      towns_hashes = JSON.parse(towns_json, symbolize_names: true)
      towns_hashes.each do |town_data|
        Town.create!(name: town_data[:nom], postal_code: town_data[:codePostal], insee_code: town_data[:code],
                     country: 'fr', apidae_id: town_data[:id])
      end
      result
    end

    def label
      "#{name} (#{postal_code})"
    end
  end
end
