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

    def self.import(zip_file, project_id)
      Zip::File.open(zip_file) do |zfile|
        result = {created: 0, updated: 0, deleted: 0, selections: []}
        project = Project.find_or_create_by(apidae_id: project_id)
        entries = zfile.entries.map {|e| e.name}
        if entries.include?(REFERENCES_FILE)
          Reference.import(zfile.read(REFERENCES_FILE))
        end
        if entries.include?(INTERNAL_FILE)
          Reference.import_internal(zfile.read(INTERNAL_FILE))
        end
        logger.info "Completed #{Reference.count} references update" if entries.include?(REFERENCES_FILE) || entries.include?(INTERNAL_FILE)
        if entries.include?(TOWNS_FILE)
          Town.import(zfile.read(TOWNS_FILE))
          logger.info "Completed #{Town.count} towns update"
        end
        zfile.each do |file|
          if file.file? && file.name.end_with?('.json')
            logger.info "Processing file : #{file.name}"
            if file.name.include?(MODIFIED_DIR)
              add_or_update_objects(zfile.read(file.name), result, project.locales, project.versions)
            elsif file.name.include?(DELETED_FILE)
              delete_objects(zfile.read(file.name), result)
            elsif file.name.include?(SELECTIONS_FILE)
              add_or_update_selections(project, zfile.read(file.name), result)
            end
          end
        end
        create(result.except(:selections)
                   .merge({remote_file: (zip_file.is_a?(File) ? zip_file.path : zip_file), status: STATUS_COMPLETE, apidae_id: project_id}))
        logger.info "Import results : #{result}"
        result
      end
    end

    def self.import_dir(project_id, dir)
      result = {created: 0, updated: 0, deleted: 0, selections: []}
      project = Project.find_or_create_by(apidae_id: project_id)
      import_updates(File.join(dir, MODIFIED_DIR), result, project.locales, project.versions)
      import_deletions(File.join(dir, DELETED_FILE), result)
      import_selections(project, File.join(dir, SELECTIONS_FILE), result)
      logger.info "Import results : #{result}"
      result
    end

    def self.import_updates(json_dir, result, locales, versions)
      if Dir.exist?(json_dir)
        Dir.foreach(json_dir) do |f|
          if f.end_with?('.json')
            json_file = File.join(json_dir, f)
            objects_json = File.read(json_file)
            add_or_update_objects(objects_json, result, locales, versions)
          end
        end
      end
    end

    def self.add_or_update_objects(objects_json, result, locales, versions)
      objects_hashes = JSON.parse(objects_json, symbolize_names: true)
      if objects_hashes.is_a?(Array)
        objects_hashes.each do |object_data|
          begin
            existing = Obj.find_by_apidae_id(object_data[:id])
            if existing
              Obj.update_object(existing, object_data, locales, versions)
              result[:updated] += 1
            else
              Obj.add_object(object_data, locales, versions)
              result[:created] += 1
            end
          rescue Exception => e
            puts "Failed to import object #{object_data[:id]}"
            puts e.message
            puts e.backtrace.join("\n")
            raise e
          end
        end
      else
        puts "Unsupported file format - Exported objects should be grouped"
        raise Exception.new('Unsupported objects format - Exported objects should be grouped')
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
        obj = Obj.find_by_apidae_id(id)
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
              obj = Obj.find_by_apidae_id(object_data[:id])
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

    def self.import_selections(project, json_file, result)
      selections_json = File.read(json_file)
      add_or_update_selections(project, selections_json, result)
    end

    def self.add_or_update_selections(project, selections_json, result)
      selections_hashes = JSON.parse(selections_json, symbolize_names: true)
      deleted_ids = Selection.where(apidae_project_id: project.id).collect {|sel| sel.apidae_id}.uniq - selections_hashes.collect {|sel| sel[:id]}
      Selection.where(apidae_id: deleted_ids).delete_all
      selections_hashes.each do |selection_data|
        logger.info "Updating selection #{selection_data[:id]}"
        Selection.add_or_update(selection_data, project.id)
      end
      result[:selections] = Selection.where(apidae_project_id: project.id)
                                .collect {|sel| {apidae_id: sel.apidae_id, reference: sel.reference, objects: sel.objects.count}}
    end
  end
end
