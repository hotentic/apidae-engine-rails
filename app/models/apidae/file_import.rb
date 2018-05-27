require 'zip'

module Apidae
  class FileImport < ActiveRecord::Base

    STATUS_PENDING = 'pending'
    STATUS_COMPLETE = 'complete'
    STATUS_CANCELLED = 'cancelled'

    TOWNS_FILE = 'communes.json'
    INTERNAL_FILE = 'criteres_internes.json'
    REFERENCES_FILE = 'elements_reference.json'
    MODIFIED_DIR = 'objets_modifies'
    DELETED_FILE = 'objets_supprimes.json'
    SELECTIONS_FILE = 'selections.json'

    def self.import(zip_file)
      Zip::File.open(zip_file) do |zfile|
        result = {created: 0, updated: 0, deleted: 0, selections: []}
        Reference.import(zfile.read(REFERENCES_FILE))
        Reference.import_internal(zfile.read(INTERNAL_FILE))
        logger.info "Completed #{Reference.count} references update"
        Town.import(zfile.read(TOWNS_FILE))
        logger.info "Completed #{Town.count} towns update"
        zfile.each do |file|
          if file.file? && file.name.end_with?('.json')
            logger.info "Processing file : #{file.name}"
            if file.name.include?(MODIFIED_DIR)
              add_or_update_objects(zfile.read(file.name), result)
            elsif file.name.include?(DELETED_FILE)
              delete_objects(zfile.read(file.name), result)
            elsif file.name.include?(SELECTIONS_FILE)
              add_or_update_selections(zfile.read(file.name), result)
            end
          end
        end
        create(result.except(:selections).merge({remote_file: zip_file, status: STATUS_COMPLETE}))
        logger.info "Import results : #{result}"
        result
      end
    end

    def self.import_dir(dir)
      result = {created: 0, updated: 0, deleted: 0, selections: []}
      import_updates(File.join(dir, MODIFIED_DIR), result)
      import_deletions(File.join(dir, DELETED_FILE), result)
      import_selections(File.join(dir,SELECTIONS_FILE), result)
      logger.info "Import results : #{result}"
      result
    end

    def self.import_updates(json_dir, result)
      if Dir.exist?(json_dir)
        Dir.foreach(json_dir) do |f|
          if f.end_with?('.json')
            json_file = File.join(json_dir, f)
            objects_json = File.read(json_file)
            add_or_update_objects(objects_json, result)
          end
        end
      end
    end

    def self.add_or_update_objects(objects_json, result)
      objects_hashes = JSON.parse(objects_json, symbolize_names: true)
      objects_hashes.each do |object_data|
        existing = Apidae::Object.find_by_apidae_id(object_data[:id])
        if existing
          Apidae::Object.update_object(existing, object_data)
          result[:updated] += 1
        else
          Apidae::Object.add_object(object_data)
          result[:created] += 1
        end
      end
    end

    def self.import_deletions(json_file, result)
      if File.exist?(json_file)
        deleted_json = File.read(json_file)
        delete_objects(deleted_json, result)
      end
    end

    def self.delete_objects(deleted_json, result)
      deleted_ids = JSON.parse(deleted_json)
      deleted_ids.each do |id|
        obj = Apidae::Object.find_by_apidae_id(id)
        if obj
          obj.destroy!
          result[:deleted] += 1
        else
          logger.info "skipping object deletion : #{id}"
        end
      end
    end

    def self.update_fields(json_dir)
      result = false
      if Dir.exist?(json_dir)
        Dir.foreach(json_dir) do |f|
          if f.end_with?('.json')
            json_file = File.join(json_dir, f)
            objects_json = File.read(json_file)
            objects_hashes = JSON.parse(objects_json, symbolize_names: true)
            objects_hashes.each do |object_data|
              obj = Apidae::Object.find_by_apidae_id(object_data[:id])
              if obj
                yield(obj, object_data)
                obj.save!
              end
            end
          end
          result = true
        end
        result
      end
    end

    # def self.load_pictures
    #   Apidae::Object.all.each do |obj|
    #     if obj.apidae_attached_files.blank? && obj.pictures.any?
    #       obj.pictures.each do |pic|
    #         begin
    #           attached = Apidae::AttachedFile.new(apidae_object_id: id, name: pic[:name], picture: URI.parse(pic[:url]),
    #                                       description: pic[:description], credits: pic[:credits])
    #           attached.save
    #         rescue OpenURI::HTTPError => e
    #           logger.error "Could not retrieve attached picture for object #{title} - Error is #{e.message}"
    #         end
    #       end
    #     end
    #   end
    # end

    def self.import_selections(json_file, result)
      selections_json = File.read(json_file)
      add_or_update_selections(selections_json, result)
    end

    def self.add_or_update_selections(selections_json, result)
      selections_hashes = JSON.parse(selections_json, symbolize_names: true)
      deleted_ids = Apidae::Selection.all.collect {|sel| sel.apidae_id}.uniq - selections_hashes.collect {|sel| sel[:id]}
      Apidae::Selection.where(apidae_id: deleted_ids).delete_all
      selections_hashes.each do |selection_data|
        logger.info "Updating selection #{selection_data[:id]}"
        Apidae::Selection.add_or_update(selection_data)
      end
      result[:selections] = Apidae::Selection.all
                                .collect {|sel| {apidae_id: sel.apidae_id, reference: sel.reference, objects: sel.objects.count}}
    end
  end
end
