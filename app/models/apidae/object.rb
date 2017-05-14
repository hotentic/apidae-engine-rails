module Apidae
  class Object < ActiveRecord::Base

    belongs_to :town, :class_name => 'Apidae::Town', foreign_key: :town_insee_code, primary_key: :insee_code
    has_many :attached_files, :class_name => 'Apidae::AttachedFile'
    has_and_belongs_to_many :selections, :class_name => 'Apidae::Selection'

    store :pictures_data, accessors: [:pictures], coder: JSON
    store :type_data, accessors: [:categories, :themes], coder: JSON
    store :contact, accessors: [:telephone, :email, :website], coder: JSON
    store :address, accessors: [:address_fields], coder: JSON
    store :openings, accessors: [:description, :opening_periods], coder: JSON

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
              existing_obj = Apidae::Object.find_by_apidae_id(object_data[:id])
              unless existing_obj
                Apidae::Object.create!(
                    apidae_id: object_data[:id],
                    apidae_type: object_data[:type],
                    apidae_subtype: node_value(object_data[type_fields[:node]], object_data[type_fields[:subtype]]),
                    title: node_value(object_data, :nom),
                    short_desc: node_value(object_data[:presentation], :descriptifCourt),
                    long_desc: node_value(object_data[:presentation], :descriptifDetaille),
                    contact: contact(object_data[:informations]),
                    address: address(object_data[:localisation][:adresse]),
                    town: town(object_data[:localisation][:adresse]),
                    latitude: latitude(object_data[:localisation]),
                    longitude: longitude(object_data[:localisation]),
                    openings: openings(object_data[:ouverture]),
                    rates: rates(object_data[:descriptionTarif]),
                    reservation: reservation(object_data[:reservation]),
                    type_data: object_data[type_fields[:node]],
                    pictures_data: pictures_urls(object_data[:illustrations])
                )
              end
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
              obj = Apidae::Object.find_by_apidae_id(object_data[:id])
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

    def self.load_pictures
      Object.all.each do |obj|
        if obj.apidae_attached_files.blank? && obj.pictures.any?
          obj.pictures.each do |pic|
            begin
              attached = AttachedFile.new(apidae_object_id: id, name: pic[:name], picture: URI.parse(pic[:url]),
                                          description: pic[:description], credits: pic[:credits])
              attached.save
            rescue OpenURI::HTTPError => e
              puts "Could not retrieve attached picture for object #{title} - Error is #{e.message}"
            end
          end
        end
      end
    end

    def self.pictures_urls(pictures_array)
      pics_data = []
      unless pictures_array.blank?
        pictures_array.select { |p| p.is_a?(Hash) && !p[:traductionFichiers].blank? }.each do |pic|
          pics_data << {
              name: node_value(pic, :nom),
              url: pic[:traductionFichiers][0][:url],
              description: node_value(pic, :legende),
              credits: node_value(pic, :copyright)
          }
        end
      end
      {pictures: pics_data}
    end

    def self.contact(information_hash)
      contact_details = {}
      contact_entries = information_hash[:moyensCommunication].nil? ? [] : information_hash[:moyensCommunication]
      contact_entries.each do |c|
        case c[:type][:id]
          when PHONE
            contact_details[:telephone] = c[:coordonnees][:fr]
          when EMAIL
            contact_details[:email] = c[:coordonnees][:fr]
          when WEBSITE
            contact_details[:website] = c[:coordonnees][:fr]
          else
        end
      end
      contact_details
    end

    def self.address(address_hash)
      computed_address = []
      computed_address << address_hash[:adresse1] unless address_hash[:adresse1].blank?
      computed_address << address_hash[:adresse2] unless address_hash[:adresse2].blank?
      computed_address << address_hash[:adresse3] unless address_hash[:adresse3].blank?
      {address_fields: computed_address}
    end

    def self.town(address_hash)
      address_hash[:commune] ? Town.find_by_apidae_id(address_hash[:commune][:id]) : nil
    end

    def self.latitude(location_hash)
      geoloc_details = location_hash[:geolocalisation]
      (geoloc_details && geoloc_details[:valide] && geoloc_details[:geoJson]) ? geoloc_details[:geoJson][:coordinates][1] : nil
    end

    def self.longitude(location_hash)
      geoloc_details = location_hash[:geolocalisation]
      (geoloc_details && geoloc_details[:valide] && geoloc_details[:geoJson]) ? geoloc_details[:geoJson][:coordinates][0] : nil
    end

    def self.openings(openings_hash)
      if openings_hash && openings_hash[:periodeEnClair]
        {description: openings_hash[:periodeEnClair][:libelleFr], opening_periods: openings_hash[:periodesOuvertures]}
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

    def contact_text
      entries = []
      JSON.parse(contact).each_pair do |k, v|
        entries << "#{k}: #{v}"
      end
      entries.join("\n")
    end

    def main_picture
      pictures.any? ? pictures[0][:url] : "/#{Rails.application.config.apidae_pictures_path}/default/logo.png"
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
