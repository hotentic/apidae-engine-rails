module Apidae
  module OverriddenFields

    [:title, :short_desc, :long_desc, :theme_desc, :private_desc, :pictures, :attachments, :openings_desc, :rates_desc,
     :includes, :excludes, :extra, :booking_desc].each do |f|
      define_method f do
        if @obj_version == DEFAULT_VERSION
          super()[@locale]
        else
          v = in_version(@obj_version)
          v ? (v.in_locale(@locale).send(f) || super()[@locale]) : super()[@locale]
        end
      end
    end
  end
end