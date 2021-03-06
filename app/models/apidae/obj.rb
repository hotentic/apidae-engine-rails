module Apidae
  class Obj < ActiveRecord::Base

    belongs_to :town, class_name: 'Apidae::Town', foreign_key: :town_insee_code, primary_key: :insee_code, optional: true
    has_many :apidae_selection_objects, class_name: 'Apidae::SelectionObject', foreign_key: :apidae_object_id
    has_many :selections, class_name: 'Apidae::Selection', source: :apidae_selection, through: :apidae_selection_objects

    attr_accessor :locale
    attr_accessor :obj_version
    attr_accessor :obj_versions

    store_accessor :title_data, :title
    store_accessor :owner_data, :owner_name, :owner_id
    store_accessor :description_data, :short_desc, :long_desc, :theme_desc, :private_desc
    store_accessor :pictures_data, :pictures
    store_accessor :attachments_data, :attachments
    store_accessor :type_data, :categories, :themes, :capacity, :classification, :labels, :chains, :area, :track,
                   :tricky_sections, :products, :audience, :animals, :animals_desc, :extra, :duration, :certifications, :business
    store_accessor :entity_data, :entity_id, :entity_name, :service_provider_id, :is_service_provider
    store_accessor :contact_data, :telephone, :email, :website, :google, :facebook, :twitter, :yelp, :trip_advisor, :fax,
                   :mobile_website, :shorty_url, :contacts
    store_accessor :location_data, :address, :place, :latitude, :longitude, :access, :territories, :environments, :altitude, :map_reference
    store_accessor :openings_data, :openings_desc, :openings_desc_mode, :openings, :time_periods, :openings_extra
    store_accessor :rates_data, :rates_desc, :rates_desc_mode, :rates, :payment_methods, :includes, :excludes, :rates_extra
    store_accessor :service_data, :services, :equipments, :comfort, :activities, :challenged, :languages
    store_accessor :booking_data, :booking_desc, :booking_entities, :visits_allowed, :visits_desc
    store_accessor :tags_data, :promo, :internal, :linked
    store_accessor :version_data, :versioned_fields

    ALL_FIELDS.each do |f|
      alias_method :"get_#{f}", :"#{f}"
      alias_method :"set_#{f}", :"#{f}="

      if LOCALIZED_FIELDS.include?(f)
        define_method "#{f}=" do |val|
          ref_obj = (@obj_version == DEFAULT_VERSION || @obj_version.nil?) ? self : in_version(@obj_version)
          current_val = ref_obj.send(:"get_#{f}") || {}
          ref_obj.send(:"set_#{f}", current_val.merge(@locale => val))
        end
      else
        define_method "#{f}=" do |val|
          ref_obj = (@obj_version == DEFAULT_VERSION || @obj_version.nil?) ? self : in_version(@obj_version)
          ref_obj.send(:"set_#{f}", val)
        end
      end

      define_method f do
        default_value = LOCALIZED_FIELDS.include?(f) ? {} : nil
        field_val = self.send(:"get_#{f}") || default_value
        unless @obj_version == DEFAULT_VERSION
          versioned_obj = in_version(@obj_version)
          if versioned_obj
            versioned_value = versioned_obj.send(:"get_#{f}") || default_value
            if versioned_obj.versioned_fields.include?(f.to_s)
              field_val = versioned_value
            elsif field_val.respond_to?('deep_merge!')
              field_val.deep_merge!(versioned_value)
            end
          end
        end
        LOCALIZED_FIELDS.include?(f) ? (field_val[@locale] || field_val[DEFAULT_LOCALE]) : field_val
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
        EQU => {node: :informationsEquipement, subtype: :rubrique},
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

    after_initialize do
      @locale = DEFAULT_LOCALE
      @obj_version = DEFAULT_VERSION
      @obj_versions = {}
    end

    def root_obj
      Obj.unscoped.where(id: root_obj_id).first
    end

    def versions
      Obj.unscoped.where(root_obj_id: id)
    end

    def in_version(v)
      if v == DEFAULT_VERSION && root_obj_id.nil?
        @obj_version = DEFAULT_VERSION
        self
      else
        if @obj_versions[v].nil?
          @obj_versions[v] = versions.where(version: v).first
      end
        @obj_versions[v]
      end
    end

    def in_locale(l)
      @locale = l
      self
    end

    def dig(*keys)
      root_key, *nested_keys = keys
      root_val = self.send(root_key)
      if root_val.blank?
        nested_keys.blank? ? root_val : nil
      elsif root_val.respond_to?(:dig)
        root_val.dig(*nested_keys)
      else
        raise ArgumentError.new('Cannot call dig with these args')
      end
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
            version_obj.versioned_fields = ApidaeDataParser.parse_versioned_fields(version_data)
            populate_fields(version_obj, version_data, locales)
            version_obj.save!
          end
        end
      end
      apidae_obj
    end

    # Note : overrides existing fields (not a merge)
    def self.populate_fields(apidae_obj, object_data, locales)
      type_fields = TYPES_DATA[object_data[:type]]
      apidae_obj.last_update = DateTime.parse(object_data[:gestion][:dateModification]) unless object_data[:gestion].blank?
      apidae_obj.owner_data = ApidaeDataParser.parse_owner_data(object_data[:gestion][:membreProprietaire]) unless object_data[:gestion].blank?
      apidae_obj.apidae_type = object_data[:type]
      apidae_obj.apidae_subtype = ApidaeDataParser.node_id(object_data[type_fields[:node]], type_fields[:subtype])
      apidae_obj.title_data = ApidaeDataParser.parse_title(object_data, *locales)
      apidae_obj.description_data = ApidaeDataParser.parse_desc_data(object_data[:presentation], object_data[:donneesPrivees], *locales)
      apidae_obj.contact_data = ApidaeDataParser.parse_contact_data(object_data[:informations], object_data[:contacts])
      apidae_obj.location_data = ApidaeDataParser.parse_location_data(object_data[:localisation], object_data[type_fields[:node]],
                                                     object_data[:territoires])
      apidae_obj.town = ApidaeDataParser.parse_town(object_data[:localisation])
      apidae_obj.openings_data = ApidaeDataParser.parse_openings(object_data[:ouverture], *locales)
      apidae_obj.rates_data = ApidaeDataParser.parse_rates(object_data[:descriptionTarif], *locales)
      apidae_obj.booking_data = ApidaeDataParser.parse_booking(object_data[:reservation], object_data[:visites], *locales)
      apidae_obj.type_data = ApidaeDataParser.parse_type_data(apidae_obj, object_data[type_fields[:node]], object_data[:prestations],
                                             object_data[:tourismeAffaires], *locales)
      apidae_obj.pictures_data = ApidaeDataParser.parse_pictures_data(object_data[:illustrations], *locales)
      apidae_obj.attachments_data = ApidaeDataParser.parse_attachments_data(object_data[:multimedias], *locales)
      apidae_obj.entity_data = ApidaeDataParser.parse_entity_fields(object_data[:informations], object_data[type_fields[:node]], object_data[:informationsPrestataireActivites])
      apidae_obj.service_data = ApidaeDataParser.parse_service_data(object_data[:prestations], object_data[type_fields[:node]])
      apidae_obj.tags_data = ApidaeDataParser.parse_tags_data(object_data[:presentation], object_data[:criteresInternes], object_data[:liens])
      apidae_obj.meta_data = object_data[:metadonnees]
    end

    def contact_text
      entries = []
      JSON.parse(contact_data).each_pair do |k, v|
        entries << "#{k}: #{v}"
      end
      entries.join("\n")
    end

    def main_picture
      pictures.blank? ? "/#{Rails.application.config.apidae_pictures_path}/default/logo.png" : pictures[0]["url"].gsub('http:', 'https:')
    end
  end
end
