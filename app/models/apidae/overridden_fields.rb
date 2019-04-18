module Apidae
  module OverriddenFields

    # Note : add non-localized fields that can be overridden in aspects (openings, rates etc...)
    LOCALIZED_FIELDS.each do |f|
      define_method f do
        if @obj_version == DEFAULT_VERSION
          val = (super() || {})[@locale]
          val ||= (super() || {})[DEFAULT_LOCALE] if root_obj_id.nil?
          val
        else
          v = in_version(@obj_version)
          v ? (v.in_locale(@locale).send(f) || super()[@locale]) : super()[@locale]
        end
      end
    end
  end
end