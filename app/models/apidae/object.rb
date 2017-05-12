module Apidae
  class Object < ActiveRecord::Base

    has_and_belongs_to_many :apidae_selections, :class_name => 'Apidae::Selection'

    TYPES_DATA = {
        'ACTIVITE' => {node: :informationsActivite, subtype: :activiteType},
        'COMMERCE_ET_SERVICE' => {node: :informationsCommerceEtService, subtype: :commerceEtServiceType},
        'DEGUSTATION' => {node: :informationsDegustation, subtype: :degustationType},
        'DOMAINE_SKIABLE' => {node: :informationsDomaineSkiable, subtype: :domaineSkiableType},
        'EQUIPEMENT' => {node: :informationsEquipement, subtype: :equipementType},
        'FETE_ET_MANIFESTATION' => {node: :informationsFeteEtManifestation, subtype: :feteEtManifestationType},
        'HEBERGEMENT_COLLECTIF' => {node: :informationsHebergementCollectif, subtype: :hebergementCollectifType},
        'HEBERGEMENT_LOCATIF' => {node: :informationsHebergementLocatif, subtype: :hebergementLocatifType},
        'HOTELLERIE' => {node: :informationsHotellerie, subtype: :hotellerieType},
        'HOTELLERIE_PLEIN_AIR' => {node: :informationsHotelleriePleinAir, subtype: :hotelleriePleinAirType},
        'PATRIMOINE_CULTUREL' => {node: :informationsPatrimoineCulturel, subtype: :patrimoineCulturelType},
        'PATRIMOINE_NATUREL' => {node: :informationsPatrimoineNaturel, subtype: :patrimoineNaturelType},
        'RESTAURATION' => {node: :informationsRestauration, subtype: :restaurationType},
        'SEJOUR_PACKAGE' => {node: :informationsSejourPackage, subtype: :sejourPackageType},
        'STRUCTURE' => {node: :informationsStructure, subtype: :structureType},
        'TERRITOIRE' => {node: :informationsTerritoire, subtype: :territoireType}
    }

    PHONE = 201
    EMAIL = 204
    WEBSITE = 205


    def self.import(json_dir)
      result = false
      if Dir.exist?(json_dir)
        Dir.foreach(json_dir) do |f|
          if f.end_with?('.json')
            json_file = File.join(json_dir, f)
            objects_json = File.read(json_file)
            objects_hashes = JSON.parse(objects_json, symbolize_names: true)
            objects_hashes.each do |object_data|
              type_fields = TYPES_DATA[object_data[:type]]
              Object.create!(
                  apidae_id: object_data[:id],
                  apidae_type: object_data[:type],
                  apidae_subtype: node_value(object_data[type_fields[:node]], object_data[type_fields[:subtype]]),
                  title: node_value(object_data, :nom),
                  short_desc: node_value(object_data[:presentation], :descriptifCourt),
                  long_desc: node_value(object_data[:presentation], :descriptifDetaille),
                  contact: contact(object_data[:informations]),
                  address: address(object_data[:localisation][:adresse]),
                  latitude: latitude(object_data[:localisation]),
                  longitude: longitude(object_data[:localisation]),
                  openings: openings(object_data[:ouverture]),
                  rates: rates(object_data[:descriptionTarif]),
                  reservation: reservation(object_data[:reservation]),
                  type_data: JSON.generate(object_data[type_fields[:node]])
              )
            end
          end
          result = true
        end
        result
      end
    end

    def self.update_fields(json_dir)
      result = false
      if Dir.exist?(json_dir)
        Dir.foreach(json_dir) do |f|
          if f.end_with?('.json')
            json_file = File.join(json_dir, f)
            objects_json = File.read(json_file)
            objects_hashes = JSON.parse(objects_json, symbolize_names: true)
            objects_hashes.each do |object_data|
              obj = Object.find_by_apidae_id(object_data[:id])
              if obj
                yield(obj, object_data)
                obj.save!
              end
            end
          end
          result = true
        end
        result
      end
    end

    def self.contact(information_hash)
      contact_details = {}
      contact_entries = information_hash[:moyensCommunication].nil? ? [] : information_hash[:moyensCommunication]
      contact_entries.each do |c|
        case c[:type][:id]
          when PHONE
            contact_details['Téléphone'] = c[:coordonnees][:fr]
          when EMAIL
            contact_details['Email'] = c[:coordonnees][:fr]
          when WEBSITE
            contact_details['Site web'] = c[:coordonnees][:fr]
          else
        end
      end
      JSON.generate(contact_details)
    end

    def contact_text
      entries = []
      JSON.parse(contact).each_pair do |k, v|
        entries << "#{k}: #{v}"
      end
      entries.join("\n")
    end

    def self.address(address_hash)
      computed_address = ''
      computed_address += "#{address_hash[:adresse1]}, " unless address_hash[:adresse1].nil?
      town = Town.find_by_external_id(address_hash[:commune][:id])
      computed_address + town.name
    end

    def self.latitude(location_hash)
      geoloc_details = location_hash[:geolocalisation]
      geoloc_details[:valide] ? geoloc_details[:geoJson][:coordinates][1] : nil
    end

    def self.longitude(location_hash)
      geoloc_details = location_hash[:geolocalisation]
      geoloc_details[:valide] ? geoloc_details[:geoJson][:coordinates][0] : nil
    end

    def self.openings(openings_hash)
      if openings_hash && openings_hash[:periodeEnClair]
        JSON.generate(
            {
                description: openings_hash[:periodeEnClair][:libelleFr],
                openings: openings_hash[:periodesOuvertures]
            }
        )
      end
    end

    def self.rates(rates_hash)
      if rates_hash
        if rates_hash[:gratuit]
          return 'gratuit'
        elsif rates_hash[:tarifsEnClair]
          rates_hash[:tarifsEnClair][:libelleFr]
        end
      end
    end

    def self.reservation(reservation_hash)
      if reservation_hash
        if reservation_hash[:complement]
          reservation_hash[:complement][:libelleFr]
        else
          reservation_hash[:organismes]
        end
      end
    end

    private

    def self.node_value(node, key)
      if node && node[key]
        node[key][:libelleFr]
      else
        ''
      end
    end
  end
end
