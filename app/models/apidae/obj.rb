module Apidae
  class Obj < ActiveRecord::Base

    belongs_to :town, class_name: 'Apidae::Town', foreign_key: :town_insee_code, primary_key: :insee_code
    # has_many :attached_files, class_name: 'Apidae::AttachedFile'
    has_many :apidae_selection_objects, class_name: 'Apidae::SelectionObject', foreign_key: :apidae_object_id
    has_many :selections, class_name: 'Apidae::Selection', source: :apidae_selection, through: :apidae_selection_objects

    store_accessor :description_data, :short_desc, :long_desc, :theme_desc
    store_accessor :pictures_data, :pictures
    store_accessor :attachments_data, :attachments
    store_accessor :type_data, :categories, :themes, :capacity, :classification, :labels, :chains, :area, :track,
                   :products, :audience, :animals, :extra, :duration
    store_accessor :entity_data, :entity_id, :entity_name
    store_accessor :contact, :telephone, :email, :website
    store_accessor :location_data, :address, :place, :latitude, :longitude, :access
    store_accessor :openings_data, :openings_desc, :openings, :time_periods
    store_accessor :rates_data, :rates_desc, :rates, :payment_methods, :included, :excluded
    store_accessor :service_data, :services, :equipments, :comfort, :activities, :challenged, :languages
    store_accessor :tags_data, :promo, :internal

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
      apidae_obj = Obj.new(apidae_id: object_data[:id])
      update_object(apidae_obj, object_data)
    end

    def self.update_object(apidae_obj, object_data)
      type_fields = TYPES_DATA[object_data[:type]]
      apidae_obj.apidae_type = object_data[:type]
      apidae_obj.apidae_subtype = node_id(object_data[type_fields[:node]], type_fields[:subtype])
      apidae_obj.title = node_value(object_data, :nom)
      apidae_obj.description_data = parse_desc_data(object_data[:presentation])
      apidae_obj.contact = contact(object_data[:informations])
      apidae_obj.location_data = parse_location_data(object_data[:localisation], object_data[type_fields[:node]])
      apidae_obj.town = town(object_data[:localisation][:adresse])
      apidae_obj.openings_data = parse_openings(object_data[:ouverture])
      apidae_obj.rates_data = parse_rates(object_data[:descriptionTarif])
      apidae_obj.reservation = parse_reservation(object_data[:reservation])
      apidae_obj.type_data = parse_type_data(apidae_obj, object_data[type_fields[:node]], object_data[:prestations])
      apidae_obj.pictures_data = pictures_urls(object_data[:illustrations])
      apidae_obj.attachments_data = attachments_urls(object_data[:multimedias])
      apidae_obj.entity_data = entity_fields(object_data[:informations])
      apidae_obj.service_data = parse_service_data(object_data[:prestations], object_data[type_fields[:node]])
      apidae_obj.tags_data = parse_tags_data(object_data[:presentation], object_data[:criteresInternes])
      apidae_obj.meta_data = object_data[:metadonnees]
      apidae_obj.save!
    end

    def self.parse_desc_data(data_hash)
      unless data_hash.blank?
        {
            short_desc: node_value(data_hash, :descriptifCourt),
            long_desc: node_value(data_hash, :descriptifDetaille),
            theme_desc: data_hash[:descriptifsThematises].blank? ? [] : Hash[data_hash[:descriptifsThematises].map {|th| [node_id(th, :theme), node_value(th, :description)]}]
        }
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

    def self.attachments_urls(attachments_array)
      atts_data = []
      unless attachments_array.blank?
        attachments_array.select { |att| att.is_a?(Hash) && !att[:traductionFichiers].blank? }.each do |att|
          atts_data << {
              name: node_value(att, :nom),
              url: att[:traductionFichiers][0][:url]
          }
        end
      end
      {attachments: atts_data}
    end

    def self.contact(information_hash)
      contact_details = {}
      contact_entries = information_hash[:moyensCommunication].nil? ? [] : information_hash[:moyensCommunication]
      contact_entries.each do |c|
        case c[:type][:id]
          when PHONE
            contact_details[:telephone] ||= []
            contact_details[:telephone] << c[:coordonnees][:fr]
          when EMAIL
            contact_details[:email] ||= []
            contact_details[:email] << c[:coordonnees][:fr]
          when WEBSITE
            contact_details[:website] ||= []
            contact_details[:website] << c[:coordonnees][:fr]
          else
        end
      end
      contact_details
    end

    def self.parse_location_data(location_hash, type_data_hash)
      unless location_hash.blank?
        address_hash = location_hash[:adresse]
        computed_address = []
        unless address_hash.blank?
          computed_address << address_hash[:adresse1] unless address_hash[:adresse1].blank?
          computed_address << address_hash[:adresse2] unless address_hash[:adresse2].blank?
          computed_address << address_hash[:adresse3] unless address_hash[:adresse3].blank?
        end
        loc_data = {address: computed_address, place: type_data_hash[:nomLieu]}
        geoloc_details = location_hash[:geolocalisation]
        if geoloc_details && geoloc_details[:valide] && geoloc_details[:geoJson]
          loc_data[:latitude] = geoloc_details[:geoJson][:coordinates][1]
          loc_data[:longitude] = geoloc_details[:geoJson][:coordinates][0]
        end
        loc_data[:access] = node_value(geoloc_details, :complement) if geoloc_details
        loc_data
      end
    end

    def self.town(address_hash = {})
      (!address_hash.blank? && address_hash[:commune]) ? Town.find_by_apidae_id(address_hash[:commune][:id]) : nil
    end

    def self.parse_openings(openings_hash)
      if openings_hash && openings_hash[:periodeEnClair]
        {
            openings_desc: openings_hash[:periodeEnClair][:libelleFr],
            openings: openings_hash[:periodesOuvertures],
            time_periods: lists_ids(openings_hash[:indicationsPeriode])
        }
      end
    end

    def self.parse_rates(rates_hash)
      if rates_hash
        desc = rates_hash[:gratuit] ? 'gratuit' : node_value(rates_hash, :tarifsEnClair)
        values = rates_hash[:periodes].blank? ? [] : rates_hash[:periodes].map {|p| build_rate(p)}
        methods = rates_hash[:modesPaiement].blank? ? [] : rates_hash[:modesPaiement].map {|p| p[:id]}
        {rates_desc: desc, rates: values, payment_methods: methods, includes: rates_hash[:leTarifComprend], excludes: rates_hash[:leTarifNeComprendPas]}
      end
    end

    def self.parse_type_data(apidae_obj, data_hash, presta_hash)
      if data_hash
        prestations_hash = presta_hash || {}
        apidae_obj.apidae_subtype = lists_ids(data_hash[:typesManifestation]).first if apidae_obj.apidae_type == FEM
        apidae_obj.apidae_subtype = node_id(data_hash, :rubrique) if apidae_obj.apidae_type == EQU
        apidae_obj.apidae_subtype = lists_ids(data_hash[:typesHebergement]).first if apidae_obj.apidae_type == SPA
        {
            categories: lists_ids(data_hash[:categories], data_hash[:typesDetailles], data_hash[:activiteCategories]),
            themes: lists_ids(data_hash[:themes]),
            capacity: data_hash[:capacite],
            classification: nodes_ids(data_hash[:classement], data_hash[:classementPrefectoral], data_hash[:classification]) +
                                      lists_ids(data_hash[:classementsGuides]) + lists_ids(data_hash[:classements]),
            labels: lists_ids(data_hash[:labels], prestations_hash[:labelsTourismeHandicap]) +
                (node_id(data_hash, :typeLabel) ? [node_id(data_hash, :typeLabel)] : []),
            chains: lists_ids(data_hash[:chaines]) + nodes_ids(data_hash[:chaineEtLabel]),
            area: apidae_obj.apidae_type == DOS ? data_hash.except(:classification) : node_value(data_hash, :lieuDePratique),
            track: apidae_obj.apidae_type == EQU ? data_hash[:itineraire] : nil,
            products: lists_ids(data_hash[:typesProduit], data_hash[:aopAocIgps], data_hash[:specialites]),
            audience: lists_ids(prestations_hash[:typesClientele]),
            animals: prestations_hash[:animauxAcceptes] == 'ACCEPTES',
            extra: apidae_obj == SPA ? node_value(data_hash, :formuleHebergement) : node_value(prestations_hash, :complementAccueil),
            duration: apidae_obj.apidae_type == SPA ? {days: data_hash[:nombreJours], nights: data_hash[:nombreNuits]} : data_hash[:dureeSeance]
        }
      end
    end

    def self.parse_service_data(data_hash, type_data_hash)
      if data_hash
        {
            services: lists_ids(data_hash[:services]),
            equipments: lists_ids(data_hash[:equipements]),
            comfort: lists_ids(data_hash[:conforts]),
            activities: lists_ids(data_hash[:activites], type_data_hash[:activites],
                                  type_data_hash[:activitesSportives], type_data_hash[:activitesCulturelles]),
            challenged: lists_ids(data_hash[:tourismesAdaptes]),
            languages: lists_ids(data_hash[:languesParlees])
        }
      end
    end

    def self.parse_tags_data(pres_data_hash, crit_data_hash)
      tags = {}
      if pres_data_hash
        tags[:promo] = lists_ids(pres_data_hash[:typologiesPromoSitra])
      end
      unless crit_data_hash.blank?
        tags[:internal] = crit_data_hash.map {|c| c[:id]}
      end
      tags
    end

    def self.parse_reservation(reservation_hash)
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
      pictures.any? ? pictures[0]["url"] : "#{Rails.application.config.apidae_pictures_path}/default/logo.png"
    end

    def self.build_rate(rate_period)
      {
          id: rate_period[:identifiant], from: rate_period[:dateDebut], to: rate_period[:dateFin],
          values: rate_period[:tarifs].blank? ? [] : rate_period[:tarifs].map {|t| {min: t[:minimum], max: t[:maximum], type: t[:type][:id], details: node_value(t, :precisionTarif)}}
      }
    end

    private

    def self.node_value(node, key)
      if node && node[key]
        node[key][:libelleFr]
      else
        ''
      end
    end

    def self.node_id(node, key)
      node[key][:id] if node && node[key]
    end

    def self.lists_ids(*lists)
      lists.blank? ? [] : lists.map {|l| l.blank? ? [] : l.map {|elt| elt[:id]}}.flatten.uniq
    end

    def self.nodes_ids(*nodes)
      nodes.blank? ? [] : nodes.select {|n| !n.blank?}.map {|n| n[:id]}
    end
  end
end