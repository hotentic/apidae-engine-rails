module Apidae
  module LocalizedFields
    def title
      super[@locale]
    end

    def short_desc
      super[@locale]
    end

    def long_desc
      super[@locale]
    end

    def theme_desc
      super[@locale]
    end

    def private_desc
      super[@locale]
    end

    def pictures
      super[@locale]
    end

    def attachments
      super[@locale]
    end

    def openings_desc
      super[@locale]
    end

    def rates_desc
      super[@locale]
    end

    def includes
      super[@locale]
    end

    def excludes
      super[@locale]
    end

    def extra
      super[@locale]
    end

    def booking_desc
      super[@locale]
    end
  end
end