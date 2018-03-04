module Apidae
  class Selection < ActiveRecord::Base
    has_many :apidae_selection_objects, class_name: 'Apidae::SelectionObject', foreign_key: :apidae_selection_id
    has_many :objects, class_name: 'Apidae::Object', source: :apidae_object, through: :apidae_selection_objects

    AGENDA_ENDPOINT = 'agenda/detaille/list-identifiants'
    SELECTION_ENDPOINT = 'recherche/list-identifiants'
    MAX_COUNT = 100
    MAX_LOOPS = 10

    validates_presence_of :apidae_id, :reference
    before_validation :generate_reference, on: :create

    def self.add_or_update(selection_data)
      apidae_sel = Apidae::Selection.where(apidae_id: selection_data[:id]).first_or_initialize
      apidae_sel.label = selection_data[:nom]
      apidae_sel.save!

      # Note : should be done with basic collection assignment, but can't make it work...
      current_objs = apidae_sel.objects.collect {|obj| obj.apidae_id}
      imported_objs = selection_data[:objetsTouristiques].blank? ? [] : selection_data[:objetsTouristiques].collect {|obj| obj[:id]}

      added = imported_objs - current_objs
      removed = current_objs - imported_objs

      added.each do |o|
        obj = Apidae::Object.find_by_apidae_id(o)
        Apidae::SelectionObject.create(apidae_selection_id: apidae_sel.id, apidae_object_id: obj.id)
      end

      removed.each do |o|
        obj = Apidae::Object.find_by_apidae_id(o)
        Apidae::SelectionObject.destroy(apidae_selection_id: apidae_sel.id, apidae_object_id: obj.id)
      end
    end

    def results(where_clause, offset, size)
      objects.includes(:town).limit(size).offset(offset).where(where_clause)
    end

    def total(where_clause)
      objects.where(where_clause).count
    end

    def api_results(opts = {})
      query_args = build_args(SELECTION_ENDPOINT, opts.merge({selection_ids: [apidae_id]}))
      query_api(query_args, true)
    end

    def api_agenda(from, to)
      query_args = build_args(AGENDA_ENDPOINT, {selection_ids: [apidae_id], from: from, to: to})
      query_api(query_args, true)
    end

    private

    def query_api(query_args, all_results = false)
      query_result = {}

      if all_results
        loops = 0
        query_args[:first] = 0
        query_args[:count] = MAX_COUNT
        response = JSON.parse get_response(query_args), symbolize_names: false
        total = response['numFound']
        query_result[:results] = response['objetTouristiqueIds'] || {}

        while total > results_count(query_result) && loops < MAX_LOOPS
          loops += 1
          query_args[:first] += MAX_COUNT
          response = JSON.parse get_response(query_args), symbolize_names: false
          merge_results(response, query_result)
        end
        query_result[:count] = total
      else
        response = JSON.parse get_response(query_args), symbolize_names: false
        query_result[:results] = response['objetTouristiqueIds'] || {}
        query_result[:count] = response['numFound']
      end
      query_result
    end

    def results_count(result)
      if result[:results] && result[:results].is_a?(Hash)
        result[:results].values.flatten.length
      else
        result[:results].blank? ? 0 : result[:results].length
      end
    end

    def get_response(args)
      response = ''
      query = JSON.generate args.except(:url)
      logger.info "Apidae API query : #{args[:url]}?query=#{query}"
      open("#{args[:url]}?query=#{CGI.escape query}") { |f|
        f.each_line {|line| response += line if line}
      }
      response
    end

    def merge_results(response, result)
      ids = response['objetTouristiqueIds']
      unless ids.nil? || ids.empty?
        if result[:results] && result[:results].is_a?(Hash)
          first_day = ids.keys.first
          if result[:results].has_key?(first_day)
            result[:results][first_day] += ids[first_day]
          else
            result[:results][first_day] = ids[first_day]
          end
          result[:results].merge!(ids.except(first_day))
        else
          result[:results] += ids
        end
      end
    end

    def build_args(endpoint, opts = {})
      {
          url: "#{Rails.application.config.apidae_api_url}/#{endpoint}",
          apiKey: Rails.application.config.apidae_api_key,
          projetId: Rails.application.config.apidae_project_id,
          first: opts[:first] || 0,
          count: opts[:count] || MAX_COUNT,
          selectionIds: opts[:selection_ids],
          dateDebut: opts[:from],
          dateFin: opts[:to],
          center: opts[:lat] && opts[:lng] ? {type: 'Point', coordinates: [opts[:lng], opts[:lat]]} : nil,
          radius: opts[:radius] ? opts[:radius].to_i : nil,
          responseFields: opts[:fields] || ['id']
      }
    end

    def generate_reference
      self.reference ||= (self.label.parameterize || self.apidae_id)
    end
  end
end
