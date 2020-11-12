module Apidae
  class Territory < ApplicationRecord
    def self.import(territories_json)
      territories_hashes = JSON.parse(territories_json, symbolize_names: true)
      territories_hashes.each do |t_data|
        t = Territory.find_or_initialize_by(apidae_id: t_data[:id])
        t.name = t_data.dig(:nom, :libelleFr)
        t.save!
      end
    end

    def self.import_file(json_file)
      territories_json = File.read(json_file)
      import(territories_json)
    end
  end
end