require 'open-uri'

module Apidae
  class Selection < ActiveRecord::Base
    has_many :apidae_selection_objects, class_name: 'Apidae::SelectionObject', foreign_key: :apidae_selection_id
    has_many :objects, class_name: 'Apidae::Obj', source: :apidae_object, through: :apidae_selection_objects
    belongs_to :apidae_project, optional: true, class_name: 'Apidae::Project', foreign_key: :apidae_project_id

    AGENDA_ENDPOINT = 'agenda/detaille/list-identifiants'
    SELECTION_ENDPOINT = 'recherche/list-identifiants'
    OBJECTS_ENDPOINT = 'recherche/list-objets-touristiques'

    MAX_COUNT = 100
    MAX_LOOPS = 10

    validates_presence_of :apidae_id, :reference
    before_validation :generate_reference, on: :create

    def self.add_or_update(selection_data, apidae_proj_id)
      apidae_sel = Selection.where(apidae_id: selection_data[:id]).first_or_initialize
      apidae_sel.label = selection_data[:nom]
      apidae_sel.apidae_project_id = apidae_proj_id
      apidae_sel.save!

      # Note : should be done with basic collection assignment, but can't make it work...
      current_objs = apidae_sel.objects.collect {|obj| obj.apidae_id}
      imported_objs = selection_data[:objetsTouristiques].blank? ? [] : selection_data[:objetsTouristiques].collect {|obj| obj[:id]}

      added = imported_objs - current_objs
      removed = current_objs - imported_objs

      added.each do |o|
        obj = Obj.find_by_apidae_id(o)
        if obj
          SelectionObject.create(apidae_selection_id: apidae_sel.id, apidae_object_id: obj.id)
        else
          logger.error "Object #{o} referenced in selection #{apidae_sel.apidae_id} and project #{apidae_sel.apidae_project.apidae_id} is unknown"
        end
      end

      removed_ids = Obj.where(apidae_id: removed).map {|o| o.id}
      SelectionObject.where(apidae_selection_id: apidae_sel.id, apidae_object_id: removed_ids).delete_all
    end

    def results(where_clause, offset, size)
      objects.includes(:town).limit(size).offset(offset).where(where_clause)
    end

    def total(where_clause)
      objects.where(where_clause).count
    end

    def valid_api?
      apidae_project && !apidae_project.api_key.blank? && !apidae_project.apidae_id.blank?
    end

    def api_results(opts = {})
      key = cache_key(:results)
      res = $apidae_cache.read(key)
      unless res
        query_args = build_args(SELECTION_ENDPOINT, opts.merge({selection_ids: [apidae_id]}))
        res = query_api(query_args, true)
        $apidae_cache.write(key, res)
      end
      res
    end

    def api_agenda(from, to)
      key = cache_key(:agenda, from, to)
      res = $apidae_cache.read(key)
      unless res
        query_args = build_args(AGENDA_ENDPOINT, {selection_ids: [apidae_id], from: from, to: to, count: 200})
        res = query_api(query_args, true)
        $apidae_cache.write(key, res)
      end
      res
    end

    def api_objects(opts = {})
      key = cache_key(:objects)
      res = $apidae_cache.read(key)
      unless res
        query_args = build_args(OBJECTS_ENDPOINT, opts.merge({selection_ids: [apidae_id]}))
        res = query_api(query_args, true, false)
        $apidae_cache.write(key, res)
      end
      res
    end

    def api_object(apidae_obj_id, fields = ["@all"])
      query_args = build_args(OBJECTS_ENDPOINT, {obj_ids: [apidae_obj_id], fields: fields})
      query_api(query_args, true, false)
    end

    # Note : WARNING - updated obj will only contain the provided fields
    def add_or_refresh_obj(apidae_obj_id, fields = ["@all"])
      if valid_api?
        res = api_object(apidae_obj_id, fields)
        if res[:results] && res[:results].length == 1
          obj_data = res[:results].first.deep_symbolize_keys
          add_or_refresh(obj_data)
        end
      end
    end

    # Note : WARNING - updated objs will only contain the provided fields
    def add_or_refresh_objs(fields = ["@all"])
      if valid_api?
        res = api_objects({fields: fields})
        if res[:results] && res[:results].length > 0
          res[:results].each do |result|
            obj_data = result.deep_symbolize_keys
            add_or_refresh(obj_data)
          end
        end
      end
    end

    def add_or_refresh(obj_data)
      obj = Obj.find_by_apidae_id(obj_data[:id])
      if obj
        obj = Obj.update_object(obj, obj_data, apidae_project.locales, apidae_project.versions)
      else
        obj = Obj.add_object(obj_data, apidae_project.locales, apidae_project.versions)
      end
      SelectionObject.create(apidae_selection_id: id, apidae_object_id: obj.id) unless objects.include?(obj)

      if Rails.application.config.respond_to?(:apidae_obj_refresh_callback)
        Rails.application.config.apidae_obj_refresh_callback.call(obj.apidae_id)
      end
      obj
    end

    def as_text
      "#{label} (#{apidae_id})"
    end

    private

    def query_api(query_args, all_results = false, only_ids = true)
      query_result = {}

      if all_results
        loops = 0
        max_loops = only_ids ? 50 : MAX_LOOPS
        query_args[:first] = 0
        query_args[:count] ||= MAX_COUNT
        query_args[:locales] ||= apidae_project && !apidae_project.locales.blank? ? apidae_project.locales : [DEFAULT_LOCALE]
        response = JSON.parse get_response(query_args), symbolize_names: false
        total = response['numFound']
        query_result[:results] = (only_ids ? response['objetTouristiqueIds'] : response['objetsTouristiques']) || {}

        while total > results_count(query_result) && loops < max_loops
          loops += 1
          query_args[:first] += MAX_COUNT
          response = JSON.parse get_response(query_args), symbolize_names: false
          if only_ids
            merge_results(response, query_result)
          else
            merge_objects_results(response, query_result)
          end
        end
        query_result[:count] = total
      else
        response = JSON.parse get_response(query_args), symbolize_names: false
        query_result[:results] = (only_ids ? response['objetTouristiqueIds'] : response['objetsTouristiques']) || {}
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

    def query_objects_api(query_args, all_results = false)
      query_result = {}

      if all_results
        loops = 0
        query_args[:first] = 0
        query_args[:count] = MAX_COUNT
        response = JSON.parse get_response(query_args), symbolize_names: false
        total = response['numFound']
        query_result[:results] = response['objetsTouristiques'] || {}

        while total > results_count(query_result) && loops < MAX_LOOPS
          loops += 1
          query_args[:first] += MAX_COUNT
          response = JSON.parse get_response(query_args), symbolize_names: false
          merge_objects_results(response, query_result)
        end
        query_result[:count] = total
      else
        response = JSON.parse get_response(query_args), symbolize_names: false
        query_result[:results] = response['objetsTouristiques'] || {}
        query_result[:count] = response['numFound']
      end
      query_result
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

    def merge_objects_results(response, result)
      objects = response['objetsTouristiques']
      unless objects.blank?
        if result[:results] && result[:results].is_a?(Array)
          result[:results] += objects
        end
      end
    end

    def build_args(endpoint, opts = {})
      {
          url: "#{Rails.application.config.apidae_api_url}/#{endpoint}",
          apiKey: apidae_project ? apidae_project.api_key : '',
          projetId: apidae_project.apidae_id,
          first: opts[:first] || 0,
          count: opts[:count] || MAX_COUNT,
          selectionIds: opts[:selection_ids],
          identifiants: opts[:obj_ids],
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

    def cache_key(*args)
      "#{apidae_id}_#{args.map {|a| a.to_s.parameterize}.join('_')}"
    end
  end
end
