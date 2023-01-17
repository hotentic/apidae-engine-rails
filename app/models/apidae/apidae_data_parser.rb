module Apidae
  class ApidaeDataParser
    PHONE = 201
    ALT_PHONE = 206
    EMAIL = 204
    WEBSITE = 205
    GOOGLE = 3789
    FACEBOOK = 207
    TWITTER = 3755
    YELP = 4007
    TRIP_ADVISOR = 4000
    FAX = 202
    MOBILE_WEBSITE = 3769
    SHORTY_URL = 4923

    CONTACTS_MAP = {
        'telephone' => PHONE,
        'email' => EMAIL,
        'website' => WEBSITE,
        'facebook' => FACEBOOK,
        'google' => GOOGLE,
        'trip_advisor' => TRIP_ADVISOR,
        'twitter' => TWITTER,
        'yelp' => YELP,
        'fax' => FAX,
        'mobile_website' => MOBILE_WEBSITE,
        'shorty_url' => SHORTY_URL
    }

    MODE_AUTO = 'auto'
    MODE_MANUAL = 'manual'

    MONDAY = 'MON'
    TUESDAY = 'TUE'
    WEDNESDAY = 'WED'
    THURSDAY = 'THU'
    FRIDAY = 'FRI'
    SATURDAY = 'SAT'
    SUNDAY = 'SUN'

    ALL_DAYS  = [MONDAY, TUESDAY, WEDNESDAY, THURSDAY, FRIDAY, SATURDAY, SUNDAY]

    WEEKDAYS_MAP = {
        'LUNDI' => MONDAY,
        'MARDI' => TUESDAY,
        'MERCREDI' => WEDNESDAY,
        'JEUDI' => THURSDAY,
        'VENDREDI' => FRIDAY,
        'SAMEDI' => SATURDAY,
        'DIMANCHE' => SUNDAY
    }

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

    def self.parse_owner_data(data_hash, polls_data)
      owner_data = {}
      unless data_hash.blank?
        owner_data.merge!({owner_name: data_hash[:nom], owner_id: data_hash[:id]})
      end
      unless polls_data.blank?
        owner_data.merge!({polls: polls_data[:enquetes] || []})
      end
      owner_data
    end

    def self.parse_desc_data(data_hash, private_data, *locales)
      unless data_hash.blank?
        {
            short_desc: node_value(data_hash, :descriptifCourt, *locales),
            long_desc: node_value(data_hash, :descriptifDetaille, *locales),
            theme_desc: data_hash[:descriptifsThematises].blank? ? {} : Hash[data_hash[:descriptifsThematises].map {|th| [node_id(th, :theme), node_value(th, :description, *locales)]}],
            private_desc: private_data.blank? ? {} : Hash[private_data.map {|d| [d[:nomTechnique], (node_value(d, :descriptif, *locales).blank? ? {LOCALE_FR => d[:libelleFr]} : node_value(d, :descriptif, *locales))]}]
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
                expiration_date: pic[:dateLimiteDePublication] || ''
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
                link: att[:link],
                description: localized_value(att, :legende, locale)
            }
          end
        end
      end
      {attachments: atts_data}
    end

    def self.parse_contact_data(information_hash, contacts_list)
      contact_details = {contacts: contacts_list}
      unless information_hash.blank?
        contact_entries = information_hash[:moyensCommunication] || []
        contact_entries.each do |c|
          case c[:type][:id]
          when PHONE, ALT_PHONE
            contact_details[:telephone] ||= {}
            contact_details[:telephone][c[:identifiant]] = {value: c[:coordonnees][:fr], description: c.dig(:observation, :libelleFr)}
          when EMAIL
            contact_details[:email] ||= {}
            contact_details[:email][c[:identifiant]] = {value: c[:coordonnees][:fr], description: c.dig(:observation, :libelleFr)}
          when WEBSITE
            contact_details[:website] ||= {}
            contact_details[:website][c[:identifiant]] = {value: c[:coordonnees][:fr], description: c.dig(:observation, :libelleFr)}
          when GOOGLE
            contact_details[:google] ||= {}
            contact_details[:google][c[:identifiant]] = {value: c[:coordonnees][:fr], description: c.dig(:observation, :libelleFr)}
          when FACEBOOK
            contact_details[:facebook] ||= {}
            contact_details[:facebook][c[:identifiant]] = {value: c[:coordonnees][:fr], description: c.dig(:observation, :libelleFr)}
          when TWITTER
            contact_details[:twitter] ||= {}
            contact_details[:twitter][c[:identifiant]] = {value: c[:coordonnees][:fr], description: c.dig(:observation, :libelleFr)}
          when YELP
            contact_details[:yelp] ||= {}
            contact_details[:yelp][c[:identifiant]] = {value: c[:coordonnees][:fr], description: c.dig(:observation, :libelleFr)}
          when TRIP_ADVISOR
            contact_details[:trip_advisor] ||= {}
            contact_details[:trip_advisor][c[:identifiant]] = {value: c[:coordonnees][:fr], description: c.dig(:observation, :libelleFr)}
          when FAX
            contact_details[:fax] ||= {}
            contact_details[:fax][c[:identifiant]] = {value: c[:coordonnees][:fr], description: c.dig(:observation, :libelleFr)}
          when MOBILE_WEBSITE
            contact_details[:mobile_website] ||= {}
            contact_details[:mobile_website][c[:identifiant]] = {value: c[:coordonnees][:fr], description: c.dig(:observation, :libelleFr)}
          when SHORTY_URL
            contact_details[:shorty_url] ||= {}
            contact_details[:shorty_url][c[:identifiant]] = {value: c[:coordonnees][:fr], description: c.dig(:observation, :libelleFr)}
          else
          end
        end
      end
      contact_details
    end

    def self.parse_location_data(location_hash, type_data_hash, territories)
      loc_data = {}
      unless location_hash.blank?
        address_hash = location_hash[:adresse] || {}
        computed_address = []
        unless address_hash.blank?
          computed_address << address_hash[:adresse1]
          computed_address << address_hash[:adresse2]
          computed_address << address_hash[:adresse3]
        end
        loc_data.merge!({address: computed_address})
        loc_data.merge!({place: (type_data_hash ? type_data_hash[:nomLieu] : nil) || address_hash[:nomDuLieu]})
        geoloc_details = location_hash[:geolocalisation]
        if geoloc_details && geoloc_details[:valide] && geoloc_details[:geoJson]
          loc_data[:latitude] = geoloc_details[:geoJson][:coordinates][1]
          loc_data[:longitude] = geoloc_details[:geoJson][:coordinates][0]
        end
        loc_data[:map_reference] = geoloc_details[:reperePlan]
        loc_data[:altitude] = geoloc_details[:altitude] if geoloc_details
        loc_data[:access] = node_value(geoloc_details, :complement) if geoloc_details
        loc_data[:environments] = location_hash[:environnements].map {|e| e[:id]} if location_hash[:environnements]
      end
      loc_data[:territories] = territories.map {|t| t[:id]} unless territories.blank?
      loc_data
    end

    # Note : use internal format for openings storage (ideally Apihours one, to merge data from both sources)
    def self.parse_openings(openings_hash, *locales)
      if openings_hash && openings_hash[:periodeEnClair]
        {
            openings_desc: node_value(openings_hash, :periodeEnClair, *locales),
            openings_desc_mode: openings_hash[:periodeEnClairGenerationMode] == 'AUTOMATIQUE' ? MODE_AUTO : MODE_MANUAL,
            openings: build_openings(openings_hash, *locales),
            all_year_long: openings_hash[:ouvertTouteLAnnee] == 'OUVERT_TOUTE_L_ANNEE' ? 'true' : 'false',
            time_periods: lists_ids(openings_hash[:indicationsPeriode]),
            openings_extra: lists_ids(openings_hash[:ouverturesComplementaires])
        }
      end
    end

    def self.parse_rates(rates_hash, *locales)
      if rates_hash
        desc = rates_hash[:gratuit] ? {DEFAULT_LOCALE => 'gratuit'} : node_value(rates_hash, :tarifsEnClair, *locales)
        values = rates_hash[:periodes].blank? ? [] : rates_hash[:periodes].map {|p| build_rate(p, *locales)}
        methods = rates_hash[:modesPaiement].blank? ? [] : rates_hash[:modesPaiement].map {|p| p[:id]}

        {
            rates_desc: desc, rates: values, payment_methods: methods,
            tax_included: rates_hash[:taxeDeSejourIncluse].blank? ? nil : (rates_hash[:taxeDeSejourIncluse] == 'OUI'),
            rates_desc_mode: rates_hash[:tarifsEnClairGenerationMode] == 'AUTOMATIQUE' ? MODE_AUTO : MODE_MANUAL,
            includes: node_value(rates_hash, :leTarifComprend, *locales),
            excludes: node_value(rates_hash, :leTarifNeComprendPas, *locales),
            rates_extra: node_value(rates_hash, :complement, *locales)
        }
      end
    end

    def self.parse_type_data(apidae_obj, type_hash, presta_hash, business_hash, *locales)
      data_hash = type_hash || {}
      prestations_hash = presta_hash || {}
      apidae_obj.apidae_subtype = lists_ids(data_hash[:typesManifestation]).first if apidae_obj.apidae_type == Obj::FEM
      apidae_obj.apidae_subtype = node_id(data_hash, :rubrique) if apidae_obj.apidae_type == Obj::EQU
      apidae_obj.apidae_subtype = lists_ids(data_hash[:typesHebergement]).first if apidae_obj.apidae_type == Obj::SPA
      {
          categories: lists_ids(data_hash[:categories], data_hash[:typesDetailles], data_hash[:activiteCategories], data_hash[:typesHabitation]),
          themes: lists_ids(data_hash[:themes]),
          capacity: (data_hash[:capacite] || {})
                        .merge(presta_hash ? {group_min: presta_hash[:tailleGroupeMin], group_max: presta_hash[:tailleGroupeMax],
                                              age_min: presta_hash[:ageMin], age_max: presta_hash[:ageMax]} : {}),
          classification: nodes_ids(data_hash[:classement], data_hash[:classementPrefectoral], data_hash[:classification]) +
              lists_ids(data_hash[:classementsGuides]) + lists_ids(data_hash[:classements]),
          classification_date: data_hash[:dateClassement],
          classification_ref: data_hash[:numeroClassement],
          labels: lists_ids(data_hash[:labels], data_hash[:labelsChartesQualite], prestations_hash[:labelsTourismeHandicap]) +
              (node_id(data_hash, :typeLabel) ? [node_id(data_hash, :typeLabel)] : []),
          chains: lists_ids(data_hash[:chaines]) + nodes_ids(data_hash[:chaineEtLabel]),
          area: apidae_obj.apidae_type == Obj::DOS ? data_hash.except(:classification) : node_value(data_hash, :lieuDePratique),
          track: apidae_obj.apidae_type == Obj::EQU ? (data_hash[:itineraire] || {}).except(:passagesDelicats) : nil,
          tricky_sections: apidae_obj.apidae_type == Obj::EQU ? node_value(data_hash[:itineraire], :passagesDelicats, *locales) : nil,
          products: lists_ids(data_hash[:typesProduit], data_hash[:aopAocIgps], data_hash[:specialites]),
          audience: lists_ids(prestations_hash[:typesClientele]),
          animals: {allowed: prestations_hash[:animauxAcceptes] == 'ACCEPTES', desc: node_value(prestations_hash, :descriptifAnimauxAcceptes, *locales),
                    fee: prestations_hash[:animauxAcceptesSupplement] ==	'AVEC_SUPPLEMENT'},
          extra: apidae_obj.apidae_type == Obj::SPA ? node_value(data_hash, :formuleHebergement, *locales) : node_value(prestations_hash, :complementAccueil, *locales),
          duration: apidae_obj.apidae_type == Obj::SPA ? {days: data_hash[:nombreJours], nights: data_hash[:nombreNuits]} : data_hash[:dureeSeance],
          certifications: data_hash[:agrements].blank? ? [] : data_hash[:agrements].map {|a| {id: a[:type][:id], identifier: a[:numero]}},
          business: (business_hash || {}).except(:sallesEquipeesPour, :sallesEquipement, :sallesRestauration, :sallesReunion, :sallesHebergement),
          business_equipments: lists_ids((business_hash || {})[:sallesEquipeesPour], (business_hash || {})[:sallesEquipement],
                                         (business_hash || {})[:sallesRestauration], (business_hash || {})[:sallesHebergement]),
          business_rooms: (business_hash || {})[:sallesReunion]
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
                            .map {|l| {apidae_id: l[:objetTouristique][:id], apidae_type: l[:objetTouristique][:type], category: l[:type]}}
      end
      tags
    end

    def self.parse_booking(reservation_hash, visits_hash, *locales)
      booking_hash = {}
      if reservation_hash
        booking_hash[:booking_desc] = node_value(reservation_hash, :complement, *locales)
        booking_hash[:booking_entities] = reservation_hash[:organismes]
      end
      if visits_hash
        booking_hash[:visits_allowed] = visits_hash[:visitable] == true
        booking_hash[:visits_desc] = node_value(visits_hash, :complementVisite, *locales)
        booking_hash[:visits_duration] = visits_hash[:dureeMoyenneVisiteIndividuelle]
        booking_hash[:visits_services] = lists_ids(visits_hash[:prestationsVisitesGroupees]) + lists_ids(visits_hash[:prestationsVisitesIndividuelles])
      end
      booking_hash
    end

    def self.parse_town(location_hash)
      if location_hash
        address_hash = location_hash[:adresse]
        (!address_hash.blank? && address_hash[:commune]) ? Town.find_by_apidae_id(address_hash[:commune][:id]) : nil
      else
        nil
      end
    end

    def self.parse_entity_fields(information_hash, type_data_hash, sp_hash)
      entity_hash = {}
      if information_hash
        if information_hash[:structureGestion]
          entity_hash.merge!({entity_id: information_hash[:structureGestion][:id], service_provider_id: node_id(type_data_hash, :prestataireActivites)})
        end

        if information_hash[:informationsLegales]
          entity_hash.merge!({legal: information_hash[:informationsLegales]})
        end
      end
      if sp_hash && sp_hash[:prestataireActivites]
        entity_hash[:is_service_provider] = true
      end
      entity_hash
    end

    def self.node_id(node, key)
      node[key][:id] if node && node[key]
    end

    private

    def self.build_rate(rate_period, *locales)
      {
          id: rate_period[:identifiant], start_date: rate_period[:dateDebut], end_date: rate_period[:dateFin],
          values: rate_period[:tarifs].blank? ? [] : rate_period[:tarifs].map {|t| {min: t[:minimum], max: t[:maximum], type: t[:type][:id], details: node_value(t, :precisionTarif, *locales)}}
      }
    end

    def self.build_openings(openings_data, *locales)
      openings_list = openings_data[:periodesOuvertures]
      closing_days = openings_data[:fermeturesExceptionnelles]
      if openings_list.blank?
        []
      else
        openings_list.map do |o|
          {
              id: o[:identifiant],
              external_id: o[:identifiantTechnique],
              start_date: o[:dateDebut],
              end_date: o[:dateFin],
              each_year: o[:tousLesAns],
              closing_days: closing_days.blank? ? [] : closing_days.map {|d| d[:dateSpeciale]},
              details: node_value(o, :complementHoraire, *locales),
              time_periods: [
                  {
                      type: 'opening',
                      weekdays: compute_weekdays(o),
                      time_frames: (o[:horaireOuverture].blank? && o[:horaireFermeture].blank?) ? [] : [{start_time: o[:horaireOuverture], end_time: o[:horaireFermeture], recurrence: nil}]
                  }
              ]
          }
        end
      end
    end

    def self.compute_weekdays(opening_data)
      if opening_data[:type] == 'OUVERTURE_TOUS_LES_JOURS'
        ALL_DAYS
      elsif opening_data[:type] == 'OUVERTURE_SAUF' && opening_data[:ouverturesJournalieres]
        closed_weekdays = opening_data[:ouverturesJournalieres].map {|d| WEEKDAYS_MAP[d[:jour]]}
        ALL_DAYS - closed_weekdays
      elsif opening_data[:type] == 'OUVERTURE_SEMAINE' && opening_data[:ouverturesJournalieres]
        opening_data[:ouverturesJournalieres].map {|d| WEEKDAYS_MAP[d[:jour]]}
      else
        []
      end
    end

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