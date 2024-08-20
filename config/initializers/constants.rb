module Apidae
  LOCALE_FR = 'fr'
  LOCALE_EN = 'en'
  LOCALE_IT = 'it'
  LOCALE_DE = 'de'
  LOCALE_NL = 'nl'
  LOCALE_RU = 'ru'
  LOCALE_ZH = 'zh'
  LOCALE_ES = 'es'
  LOCALE_PT_BR = 'pt-BR'
  LOCALE_JP = 'jp'

  DEFAULT_LOCALE = LOCALE_FR
  ALL_LOCALES = [LOCALE_FR, LOCALE_EN, LOCALE_IT, LOCALE_DE, LOCALE_NL, LOCALE_RU, LOCALE_ZH, LOCALE_ES, LOCALE_PT_BR, LOCALE_JP]

  STANDARD_VERSION = 'STANDARD'
  WINTER_VERSION = 'HIVER'
  SUMMER_VERSION = 'ETE'
  CHALLENGED_VERSION = 'HANDICAP'
  BUSINESS_VERSION = 'TOURISME_AFFAIRES'
  GROUPS_VERSION = 'GROUPES'
  ACTIVITIES_VERSION = 'PRESTATAIRE_ACTIVITES'

  DEFAULT_VERSION = STANDARD_VERSION
  ALL_VERSIONS = [STANDARD_VERSION, WINTER_VERSION, SUMMER_VERSION, CHALLENGED_VERSION, BUSINESS_VERSION,
                  GROUPS_VERSION, ACTIVITIES_VERSION]

  LOCALIZED_FIELDS = [:title, :short_desc, :long_desc, :pictures, :attachments,
                      :openings_desc, :rates_desc, :includes, :excludes, :extra, :booking_desc]
  ALL_FIELDS = LOCALIZED_FIELDS + [:theme_desc, :private_desc, :accessibility_desc, :capacity, :telephone, :email, :website,
                                   :google, :facebook, :twitter, :yelp, :trip_advisor, :fax, :mobile_website, :shorty_url, :instagram,
                                   :openings, :openings_extra, :rates, :services, :payment_methods, :categories, :themes,
                                   :labels, :chains, :classification, :challenged, :environments, :languages, :products,
                                   :animals, :equipments, :comfort, :activities, :promo, :internal, :linked]
end
