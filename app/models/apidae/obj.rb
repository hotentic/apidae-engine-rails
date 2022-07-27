module Apidae
  class Obj < ActiveRecord::Base

    belongs_to :town, class_name: 'Apidae::Town', foreign_key: :town_insee_code, primary_key: :insee_code, optional: true
    has_many :apidae_selection_objects, class_name: 'Apidae::SelectionObject', foreign_key: :apidae_object_id
    has_many :selections, class_name: 'Apidae::Selection', source: :apidae_selection, through: :apidae_selection_objects

    attr_accessor :locale
    attr_accessor :obj_version

    store_accessor :title_data, :title
    store_accessor :owner_data, :owner_name, :owner_id
    store_accessor :description_data, :short_desc, :long_desc, :theme_desc, :private_desc
    store_accessor :pictures_data, :pictures
    store_accessor :attachments_data, :attachments
    store_accessor :type_data, :categories, :themes, :capacity, :classification, :labels, :chains, :area, :track,
                   :products, :audience, :animals, :extra, :duration, :certifications, :business
    store_accessor :entity_data, :entity_id, :entity_name, :service_provider_id
    store_accessor :contact, :telephone, :email, :website
    store_accessor :location_data, :address, :place, :latitude, :longitude, :access, :territories, :environments
    store_accessor :openings_data, :openings_desc, :openings_desc_mode, :openings, :time_periods, :openings_extra
    store_accessor :rates_data, :rates_desc, :rates_desc_mode, :rates, :payment_methods, :includes, :excludes
    store_accessor :service_data, :services, :equipments, :comfort, :activities, :challenged, :languages
    store_accessor :booking_data, :booking_desc, :booking_entities
    store_accessor :tags_data, :promo, :internal, :linked
    store_accessor :version_data, :versioned_fields

    LOCALIZED_FIELDS.each do |f|
      alias_method :"#{f}_hash", :"#{f}"
      alias_method :"#{f}_hash=", :"#{f}="

      define_method "#{f}=" do |val|
        ref_obj = (@obj_version == DEFAULT_VERSION || @obj_version.nil?) ? self : in_version(@obj_version)
        field_hash = ref_obj.send(:"#{f}_hash") || {}
        ref_obj.send(:"#{f}_hash=", field_hash.merge(@locale => val))
      end

      define_method f do
        field_hash = self.send(:"#{f}_hash") || {}
        unless @obj_version == DEFAULT_VERSION
          versioned_obj = in_version(@obj_version)
          if versioned_obj
            versioned_hash = versioned_obj.send(:"#{f}_hash") || {}
            if versioned_obj.versioned_fields.include?(f.to_s)
              field_hash = versioned_hash
            else
              field_hash.deep_merge!(versioned_hash)
            end
          end
        end
        field_hash[@locale] || field_hash[DEFAULT_LOCALE]
      end
    end

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

    MODE_AUTO = 'auto'
    MODE_MANUAL = 'manual'

    after_initialize do
      @locale = DEFAULT_LOCALE
      @obj_version = DEFAULT_VERSION
    end

    def root_obj
      Obj.unscoped.where(id: root_obj_id).first
    end

    def versions
      Obj.unscoped.where(root_obj_id: id)
    end

    def in_version(v)
      versions.where(version: v).first
    end

    def in_locale(l)
      @locale = l
      self
    end

    def self.default_scope
      where(root_obj_id: nil)
    end

    def self.add_object(object_data, locales, versions)
      apidae_obj = Obj.new(apidae_id: object_data[:id], version: DEFAULT_VERSION)
      update_object(apidae_obj, object_data, locales, versions)
    end

    def self.update_object(apidae_obj, object_data, locales, versions)
      populate_fields(apidae_obj, object_data, locales)
      apidae_obj.save!

      unless versions.blank? || object_data[:aspects].blank?
        versions.select {|v| v != STANDARD_VERSION }.each do |version|
          version_data = object_data[:aspects].find {|a| a[:aspect] == version}
          if version_data
            version_data[:type] = apidae_obj.apidae_type
            version_obj = apidae_obj.in_version(version) || Obj.new(apidae_id: apidae_obj.apidae_id,
                                                                    root_obj_id: apidae_obj.id, version: version)
            version_obj.versioned_fields = parse_versioned_fields(version_data)
            populate_fields(version_obj, version_data, locales)
            version_obj.save!
          end
        end
      end
      apidae_obj
    end

    def self.populate_fields(apidae_obj, object_data, locales)
      type_fields = TYPES_DATA[object_data[:type]]
      apidae_obj.last_update = DateTime.parse(object_data[:gestion][:dateModification]) unless object_data[:gestion].blank?
      apidae_obj.owner_data = parse_owner_data(object_data[:gestion][:membreProprietaire]) unless object_data[:gestion].blank?
      apidae_obj.apidae_type = object_data[:type]
      apidae_obj.apidae_subtype = node_id(object_data[type_fields[:node]], type_fields[:subtype])
      apidae_obj.title_data = parse_title(object_data, *locales)
      apidae_obj.description_data = parse_desc_data(object_data[:presentation], object_data[:donneesPrivees], *locales)
      apidae_obj.contact = contact(object_data[:informations])
      apidae_obj.location_data = parse_location_data(object_data[:localisation], object_data[type_fields[:node]],
                                                     object_data[:territoires])
      apidae_obj.town = town(object_data[:localisation])
      apidae_obj.openings_data = parse_openings(object_data[:ouverture], *locales)
      apidae_obj.rates_data = parse_rates(object_data[:descriptionTarif], *locales)
      apidae_obj.booking_data = parse_booking(object_data[:reservation], *locales)
      apidae_obj.type_data = parse_type_data(apidae_obj, object_data[type_fields[:node]], object_data[:prestations],
                                             object_data[:tourismeAffaires], *locales)
      apidae_obj.pictures_data = parse_pictures_data(object_data[:illustrations], *locales)
      apidae_obj.attachments_data = parse_attachments_data(object_data[:multimedias], *locales)
      apidae_obj.entity_data = entity_fields(object_data[:informations], object_data[type_fields[:node]])
      apidae_obj.service_data = parse_service_data(object_data[:prestations], object_data[type_fields[:node]])
      apidae_obj.tags_data = parse_tags_data(object_data[:presentation], object_data[:criteresInternes], object_data[:liens])
      apidae_obj.meta_data = object_data[:metadonnees]
    end

    def self.non_empty(data_hash)
      data_hash.keep_if {|k, v| !v.blank?}
    end

    def self.parse_versioned_fields(data_hash)
      version_fields = data_hash[:champsAspect] || []
      matched_fields = []
      version_fields.each do |f|
        case f
        when 'nom'
          matched_fields << 'title'
        when 'presentation.descriptifCourt'
          matched_fields << 'short_desc'
        when 'presentation.descriptifDetaille'
          matched_fields << 'long_desc'
        when 'illustrations'
          matched_fields << 'pictures'
        when 'multimedias'
          matched_fields << 'attachments'
        when 'informations.moyensCommunication'
          matched_fields << 'contact'
        when 'descriptifsThematises'
          matched_fields << 'theme_desc'
        when 'ouverture.periodesOuvertures', 'ouverture.periodeEnClair'
          matched_fields << 'openings_desc'
          matched_fields << 'openings'
        when 'ouverture.periodeEnClairAutomatique'
          matched_fields << 'openings_desc_mode'
        when 'descriptionTarif.tarifsEnClair', 'descriptionTarif.periodes'
          matched_fields << 'rates_desc'
          matched_fields << 'rates'
        when 'descriptionTarif.tarifsEnClairAutomatique'
          matched_fields << 'rates_desc_mode'
        when 'prestations.equipements'
          matched_fields << 'equipments'
        when 'prestations.activites'
          matched_fields << 'activities'
        when 'prestations.services'
          matched_fields << 'services'
        when 'localisation.environnements'
          matched_fields << 'environments'
        when 'prestations.complementAccueil'
          matched_fields << 'extra'
        when 'localisation.geolocalisation.complement'
          matched_fields << 'access'
        else
        end
      end
      matched_fields.uniq
    end

    def self.parse_title(data_hash, *locales)
      {title: node_value(data_hash, :nom, *locales)}
    end

    def self.parse_owner_data(data_hash)
      unless data_hash.blank?
        {owner_name: data_hash[:nom], owner_id: data_hash[:id]}
      end
    end

    def self.parse_desc_data(data_hash, private_data, *locales)
      unless data_hash.blank?
        {
            short_desc: node_value(data_hash, :descriptifCourt, *locales),
            long_desc: node_value(data_hash, :descriptifDetaille, *locales),
            theme_desc: data_hash[:descriptifsThematises].blank? ? {} : Hash[data_hash[:descriptifsThematises].map {|th| [node_id(th, :theme), node_value(th, :description, *locales)]}],
            private_desc: private_data.blank? ? {} : Hash[private_data.map {|d| [d[:nomTechnique], node_value(d, :descriptif, *locales)]}]
        }
      end
    end

    def self.parse_pictures_data(pictures_array, *locales)
      pics_data = {}
      unless pictures_array.blank?
        l = locales.blank? ? [DEFAULT_LOCALE] : locales
        l.each do |locale|
          pics_data[locale] = []
          pictures_array.select { |p| p.is_a?(Hash) && !p[:traductionFichiers].blank? }.each do |pic|
            pics_data[locale] << {
                id: pic[:identifiant],
                name: localized_value(pic, :nom, locale),
                url: pic[:traductionFichiers][0][:url].gsub('http:', 'https:'),
                description: localized_value(pic, :legende, locale),
                credits: localized_value(pic, :copyright, locale),
                expiration_date: pic[:dateLimiteDePublication]
            }
          end
        end
      end
      {pictures: pics_data}
    end

    def self.parse_attachments_data(attachments_array, *locales)
      atts_data = {}
      unless attachments_array.blank?
        l = locales.blank? ? [DEFAULT_LOCALE] : locales
        l.each do |locale|
          atts_data[locale] = []
          attachments_array.select { |att| att.is_a?(Hash) && !att[:traductionFichiers].blank? }.each do |att|
            atts_data[locale] << {
                id: att[:identifiant],
                name: localized_value(att, :nom, locale),
                url: att[:traductionFichiers][0][:url].gsub('http:', 'https:'),
                type: att[:type],
                description: localized_value(att, :legende, locale)
            }
          end
        end
      end
      {attachments: atts_data}
    end

    def self.contact(information_hash)
      contact_details = {}
      unless information_hash.blank?
        contact_entries = information_hash[:moyensCommunication] || []
        contact_entries.each do |c|
          case c[:type][:id]
          when PHONE
            contact_details[:telephone] ||= []
            contact_details[:telephone] << c[:coordonnees][:fr]
            contact_details[:telephone_details] ||= []
            contact_details[:telephone_details] << {value: c[:coordonnees][:fr], description: c.dig(:observation, :libelleFr)}
          when EMAIL
            contact_details[:email] ||= []
            contact_details[:email] << c[:coordonnees][:fr]
            contact_details[:email_details] ||= []
            contact_details[:email_details] << {value: c[:coordonnees][:fr], description: c.dig(:observation, :libelleFr)}
          when WEBSITE
            contact_details[:website] ||= []
            contact_details[:website] << c[:coordonnees][:fr]
            contact_details[:website_details] ||= []
            contact_details[:website_details] << {value: c[:coordonnees][:fr], description: c.dig(:observation, :libelleFr)}
          else
          end
        end
      end
      contact_details
    end

    def self.parse_location_data(location_hash, type_data_hash, territories)
      loc_data = {}
      unless location_hash.blank?
        address_hash = location_hash[:adresse]
        computed_address = []
        unless address_hash.blank?
          computed_address << address_hash[:adresse1] unless address_hash[:adresse1].blank?
          computed_address << address_hash[:adresse2] unless address_hash[:adresse2].blank?
          computed_address << address_hash[:adresse3] unless address_hash[:adresse3].blank?
        end
        loc_data.merge!({address: computed_address})
        loc_data.merge!({place: type_data_hash[:nomLieu]}) if type_data_hash
        geoloc_details = location_hash[:geolocalisation]
        if geoloc_details && geoloc_details[:valide] && geoloc_details[:geoJson]
          loc_data[:latitude] = geoloc_details[:geoJson][:coordinates][1]
          loc_data[:longitude] = geoloc_details[:geoJson][:coordinates][0]
        end
        loc_data[:access] = node_value(geoloc_details, :complement) if geoloc_details
        loc_data[:environments] = location_hash[:environnements].map {|e| e[:id]} if location_hash[:environnements]
      end
      loc_data[:territories] = territories.map {|t| t[:id]} unless territories.blank?
      loc_data
    end

    def self.town(location_hash)
      if location_hash
        address_hash = location_hash[:adresse]
        (!address_hash.blank? && address_hash[:commune]) ? Town.find_by_apidae_id(address_hash[:commune][:id]) : nil
      else
        nil
      end
    end

    def self.parse_openings(openings_hash, *locales)
      if openings_hash && openings_hash[:periodeEnClair]
        {
            openings_desc: node_value(openings_hash, :periodeEnClair, *locales),
            openings_desc_mode: openings_hash[:periodeEnClairGenerationMode] == 'AUTOMATIQUE' ? MODE_AUTO : MODE_MANUAL,
            openings: openings_hash[:periodesOuvertures],
            time_periods: lists_ids(openings_hash[:indicationsPeriode]),
            openings_extra: lists_ids(openings_hash[:ouverturesComplementaires])
        }
      end
    end

    def self.parse_rates(rates_hash, *locales)
      if rates_hash
        desc = rates_hash[:gratuit] ? {DEFAULT_LOCALE => 'gratuit'} : node_value(rates_hash, :tarifsEnClair, *locales)
        values = rates_hash[:periodes].blank? ? [] : rates_hash[:periodes].map {|p| build_rate(p)}
        methods = rates_hash[:modesPaiement].blank? ? [] : rates_hash[:modesPaiement].map {|p| p[:id]}
        {
            rates_desc: desc, rates: values, payment_methods: methods,
            rates_desc_mode: rates_hash[:tarifsEnClairGenerationMode] == 'AUTOMATIQUE' ? MODE_AUTO : MODE_MANUAL,
            includes: node_value(rates_hash, :leTarifComprend, *locales),
            excludes: node_value(rates_hash, :leTarifNeComprendPas, *locales)
        }
      end
    end

    def self.parse_type_data(apidae_obj, type_hash, presta_hash, business_hash, *locales)
      data_hash = type_hash || {}
      prestations_hash = presta_hash || {}
      apidae_obj.apidae_subtype = lists_ids(data_hash[:typesManifestation]).first if apidae_obj.apidae_type == FEM
      apidae_obj.apidae_subtype = node_id(data_hash, :rubrique) if apidae_obj.apidae_type == EQU
      apidae_obj.apidae_subtype = lists_ids(data_hash[:typesHebergement]).first if apidae_obj.apidae_type == SPA
      {
          categories: lists_ids(data_hash[:categories], data_hash[:typesDetailles], data_hash[:activiteCategories]),
          themes: lists_ids(data_hash[:themes]),
          capacity: (data_hash[:capacite] || {})
                        .merge(presta_hash ? {group_min: presta_hash[:tailleGroupeMin], group_max: presta_hash[:tailleGroupeMax],
                                              age_min: presta_hash[:ageMin], age_max: presta_hash[:ageMax]} : {}),
          classification: nodes_ids(data_hash[:classement], data_hash[:classementPrefectoral], data_hash[:classification]) +
                                    lists_ids(data_hash[:classementsGuides]) + lists_ids(data_hash[:classements]),
          labels: lists_ids(data_hash[:labels], data_hash[:labelsChartesQualite], prestations_hash[:labelsTourismeHandicap]) +
              (node_id(data_hash, :typeLabel) ? [node_id(data_hash, :typeLabel)] : []),
          chains: lists_ids(data_hash[:chaines]) + nodes_ids(data_hash[:chaineEtLabel]),
          area: apidae_obj.apidae_type == DOS ? data_hash.except(:classification) : node_value(data_hash, :lieuDePratique),
          track: apidae_obj.apidae_type == EQU ? data_hash[:itineraire] : nil,
          products: lists_ids(data_hash[:typesProduit], data_hash[:aopAocIgps], data_hash[:specialites]),
          audience: lists_ids(prestations_hash[:typesClientele]),
          animals: prestations_hash[:animauxAcceptes] == 'ACCEPTES',
          extra: apidae_obj.apidae_type == SPA ? node_value(data_hash, :formuleHebergement, *locales) : node_value(prestations_hash, :complementAccueil, *locales),
          duration: apidae_obj.apidae_type == SPA ? {days: data_hash[:nombreJours], nights: data_hash[:nombreNuits]} : data_hash[:dureeSeance],
          certifications: data_hash[:agrements].blank? ? [] : data_hash[:agrements].map {|a| {id: a[:type][:id], identifier: a[:numero]}},
          business: business_hash
      }
    end

    def self.parse_service_data(data_hash, type_data_hash)
      if data_hash
        {
            services: lists_ids(data_hash[:services]),
            equipments: lists_ids(data_hash[:equipements]),
            comfort: lists_ids(data_hash[:conforts]),
            activities: lists_ids(data_hash[:activites], type_data_hash ? type_data_hash[:activites] : [],
                                  type_data_hash ? type_data_hash[:activitesSportives] : [],
                                  type_data_hash ? type_data_hash[:activitesCulturelles] : []),
            challenged: lists_ids(data_hash[:tourismesAdaptes]),
            languages: lists_ids(data_hash[:languesParlees])
        }
      end
    end

    def self.parse_tags_data(pres_data_hash, crit_data_hash, linked_data_hash)
      tags = {}
      if pres_data_hash
        tags[:promo] = lists_ids(pres_data_hash[:typologiesPromoSitra])
      end
      unless crit_data_hash.blank?
        tags[:internal] = crit_data_hash.map {|c| c[:id]}
      end
      unless linked_data_hash.blank? || linked_data_hash[:liensObjetsTouristiquesTypes].blank?
        tags[:linked] = linked_data_hash[:liensObjetsTouristiquesTypes]
                            .map {|l| {apidae_id: l[:objetTouristique][:id], apidae_type: l[:objetTouristique][:type], category: l[:type], name: l[:objetTouristique][:nom]}}
      end
      tags
    end

    def self.parse_booking(reservation_hash, *locales)
      if reservation_hash
        {
            booking_desc: node_value(reservation_hash, :complement, *locales),
            booking_entities: reservation_hash[:organismes]
        }
      end
    end

    def self.entity_fields(information_hash, type_data_hash)
      if information_hash && information_hash[:structureGestion]
        {entity_id: information_hash[:structureGestion][:id], service_provider_id: node_id(type_data_hash, :prestataireActivites)}
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
      pictures.blank? ? "/#{Rails.application.config.apidae_pictures_path}/default/logo.png" : pictures[0]["url"].gsub('http:', 'https:')
    end

    def self.build_rate(rate_period)
      {
          id: rate_period[:identifiant], from: rate_period[:dateDebut], to: rate_period[:dateFin],
          values: rate_period[:tarifs].blank? ? [] : rate_period[:tarifs].map {|t| {min: t[:minimum], max: t[:maximum], type: t[:type][:id], details: node_value(t, :precisionTarif)}}
      }
    end

    private

    def self.node_value(node, key, *locales)
      l = locales.blank? ? [DEFAULT_LOCALE] : locales
      locales_map = Hash[l.map {|loc| [localized_key(loc), loc]}]
      if node && node[key]
        node[key].slice(*locales_map.keys).transform_keys {|k| locales_map[k]}
      else
        {}
      end
    end

    def self.localized_value(node, key, loc)
      if node && node[key]
        node[key][localized_key(loc)]
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

    def self.localized_key(loc = DEFAULT_LOCALE)
      "libelle#{loc.camelize.gsub('-', '')}".to_sym
    end
  end
end
