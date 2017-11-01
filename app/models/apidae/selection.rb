module Apidae
  class Selection < ActiveRecord::Base
    has_and_belongs_to_many :objects, :class_name => 'Apidae::Object'

    MAX_COUNT = 100
    MAX_LOOPS = 10

    validates_presence_of :apidae_id, :reference

    before_validation :generate_reference, on: :create

    def self.add_or_update(selection_data)
      apidae_sel = Apidae::Selection.where(apidae_id: selection_data[:id]).first_or_initialize
      apidae_sel.label = selection_data[:nom]
      apidae_sel.save!

      current_objs = apidae_sel.objects.collect {|obj| obj.apidae_id}
      imported_objs = selection_data[:objetsTouristiques].blank? ? [] : selection_data[:objetsTouristiques].collect {|obj| obj[:id]}
      added = imported_objs - current_objs
      removed = current_objs - imported_objs

      added.each do |o|
        apidae_object = Apidae::Object.find_by_apidae_id(o)
        apidae_sel.objects << apidae_object if apidae_object
      end

      removed.each do |o|
        apidae_object = Apidae::Object.find_by_apidae_id(o)
        apidae_sel.objects.delete(apidae_object) if apidae_object
      end
    end

    def agenda(from, to)
      agenda_entries = Rails.cache.read("#{apidae_id}_#{from}_#{to}")
      if agenda_entries.nil?
        query_result = {}
        config = {
            url: "#{Rails.application.config.apidae_api_url}/agenda/detaille/list-identifiants",
            apiKey: Rails.application.config.apidae_api_key,
            projetId: Rails.application.config.apidae_project_id,
            first: 0,
            count: MAX_COUNT,
            selectionIds: [apidae_id],
            dateDebut: from,
            dateFin: to
        }

        loops = 0

        response = JSON.parse get_response(config), symbolize_names: false
        total = response['numFound']

        query_result[:results] = response['objetTouristiqueIds'] || {}

        while total > query_result[:results].values.flatten.length && loops < MAX_LOOPS
          loops += 1
          config[:first] += MAX_COUNT
          response = JSON.parse get_response(config), symbolize_names: false
          merge_results(response, query_result)
        end
        query_result[:count] = total
        agenda_entries = query_result
        Rails.cache.write("#{apidae_id}_#{from}_#{to}", query_result)
      end
      agenda_entries
    end

    private

    def get_response(config)
      response = ''
      query = JSON.generate config.except(:url)
      logger.info "Agenda query : #{config[:url]}?query=#{query}"
      open("#{config[:url]}?query=#{CGI.escape query}") { |f|
        f.each_line {|line| response += line if line}
      }
      response
    end

    def merge_results(response, query_results)
      unless response['objetTouristiqueIds'].nil? || response['objetTouristiqueIds'].empty?
        first_day = response['objetTouristiqueIds'].keys.first
        if query_results[:results].has_key?(first_day)
          query_results[:results][first_day] += response['objetTouristiqueIds'][first_day]
        else
          query_results[:results][first_day] = response['objetTouristiqueIds'][first_day]
        end
        query_results[:results].merge!(response['objetTouristiqueIds'].except(first_day))
      end
    end

    def generate_reference
      self.reference ||= (self.label.parameterize || self.apidae_id)
    end
  end
end
