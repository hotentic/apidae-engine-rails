module Apidae
  class Object < ActiveRecord::Base

    belongs_to :town, :class_name => 'Apidae::Town', foreign_key: :town_insee_code, primary_key: :insee_code
    has_many :attached_files, :class_name => 'Apidae::AttachedFile'
    has_and_belongs_to_many :selections, :class_name => 'Apidae::Selection'

    store :pictures_data, accessors: [:pictures], coder: JSON
    store :type_data, accessors: [:categories, :themes], coder: JSON
    store :entity_data, accessors: [:entity_id, :entity_name]
    store :contact, accessors: [:telephone, :email, :website], coder: JSON
    store :address, accessors: [:address_fields], coder: JSON
    store :openings, accessors: [:description, :opening_periods], coder: JSON

    ACT = 'ACTIVITE'
    COS = 'COMMERCE_ET_SERVICE'
    DEG = 'DEGUSTATION'
    DOS = 'DOMAINE_SKIABLE'
    EQU = 'EQUIPEMENT'
    FEM = 'FETE_ET_MANIFESTATION'
    HCO = 'HEBERGEMENT_COLLECTIF'
    HLO = 'HEBERGEMENT_LOCATIF'
    HOT = 'HOTELLERIE'
    HPA = 'HOTELLERIE_PLEIN_AIR'
    PCU = 'PATRIMOINE_CULTUREL'
    PNA = 'PATRIMOINE_NATUREL'
    RES = 'RESTAURATION'
    SPA = 'SEJOUR_PACKAGE'
    STR = 'STRUCTURE'
    TER = 'TERRITOIRE'

    TYPES_DATA = {
        ACT => {node: :informationsActivite, subtype: :activiteType},
        COS => {node: :informationsCommerceEtService, subtype: :commerceEtServiceType},
        DEG => {node: :informationsDegustation, subtype: :degustationType},
        DOS => {node: :informationsDomaineSkiable, subtype: :domaineSkiableType},
        EQU => {node: :informationsEquipement, subtype: :equipementType},
        FEM => {node: :informationsFeteEtManifestation, subtype: :feteEtManifestationType},
        HCO => {node: :informationsHebergementCollectif, subtype: :hebergementCollectifType},
        HLO => {node: :informationsHebergementLocatif, subtype: :hebergementLocatifType},
        HOT => {node: :informationsHotellerie, subtype: :hotellerieType},
        HPA => {node: :informationsHotelleriePleinAir, subtype: :hotelleriePleinAirType},
        PCU => {node: :informationsPatrimoineCulturel, subtype: :patrimoineCulturelType},
        PNA => {node: :informationsPatrimoineNaturel, subtype: :patrimoineNaturelType},
        RES => {node: :informationsRestauration, subtype: :restaurationType},
        SPA => {node: :informationsSejourPackage, subtype: :sejourPackageType},
        STR => {node: :informationsStructure, subtype: :structureType},
        TER => {node: :informationsTerritoire, subtype: :territoireType}
    }

    PHONE = 201
    EMAIL = 204
    WEBSITE = 205

    def self.add_object(object_data)
      apidae_obj = Apidae::Object.new(apidae_id: object_data[:id])
      update_object(apidae_obj, object_data)
    end

    def self.update_object(apidae_obj, object_data)
      type_fields = TYPES_DATA[object_data[:type]]
      apidae_obj.apidae_type = object_data[:type]
      apidae_obj.apidae_subtype = node_value(object_data[type_fields[:node]], object_data[type_fields[:subtype]])
      apidae_obj.title = node_value(object_data, :nom)
      apidae_obj.short_desc = node_value(object_data[:presentation], :descriptifCourt)
      apidae_obj.long_desc = node_value(object_data[:presentation], :descriptifDetaille)
      apidae_obj.contact = contact(object_data[:informations])
      apidae_obj.address = address(object_data[:localisation][:adresse])
      apidae_obj.town = town(object_data[:localisation][:adresse])
      apidae_obj.latitude = latitude(object_data[:localisation])
      apidae_obj.longitude = longitude(object_data[:localisation])
      apidae_obj.openings = openings(object_data[:ouverture])
      apidae_obj.rates = rates(object_data[:descriptionTarif])
      apidae_obj.reservation = reservation(object_data[:reservation])
      apidae_obj.type_data = object_data[type_fields[:node]]
      apidae_obj.pictures_data = pictures_urls(object_data[:illustrations])
      apidae_obj.entity_data = entity_fields(object_data[:informations])
      apidae_obj.save!
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

    def self.entity_fields(information_hash)
      if information_hash && information_hash[:structureGestion]
        {entity_id: information_hash[:structureGestion][:id]}
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
