module Apidae
  class Project < ActiveRecord::Base
    has_many :apidae_selections, class_name: 'Apidae::Selection', foreign_key: :apidae_project_id

    validates_presence_of :apidae_id
    validates_uniqueness_of :apidae_id

    def locales
      locales_data.blank? ? [] : locales_data.split('|')
    end

    def locales=(values)
      self.locales_data = values.blank? ? nil : values.join('|')
    end

    def versions
      versions_data.blank? ? [] : versions_data.split('|')
    end

    def versions=(values)
      self.versions_data = values.blank? ? nil : values.join('|')
    end

    def cleanup_selections
      apidae_selections.reload.each do |s|
        s.cleanup
      end
    end
  end
end