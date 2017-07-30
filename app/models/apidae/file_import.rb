module Apidae
  class FileImport < ActiveRecord::Base

    STATUS_PENDING = 'pending'
    STATUS_COMPLETE = 'complete'
    STATUS_CANCELLED = 'cancelled'

    MODIFIED_DIR = 'objets_modifies'
    DELETED_FILE = 'objets_supprimes.json'
    SELECTIONS_FILE = 'selections.json'

    def self.import(dir)
      puts 'Update results : '
      puts import_updates(File.join(dir, MODIFIED_DIR))
      puts '------'
      puts 'Deletion results : '
      puts import_deletions(File.join(dir, DELETED_FILE))
      puts '------'
      puts 'Selection results : '
      puts import_selections(File.join(dir,SELECTIONS_FILE))
      puts '------'
    end

    def self.import_updates(json_dir)
      result = {success: false, created: 0, updated: 0}
      if Dir.exist?(json_dir)
        Dir.foreach(json_dir) do |f|
          if f.end_with?('.json')
            json_file = File.join(json_dir, f)
            objects_json = File.read(json_file)
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
          result[:success] = true
        end
      end
      result
    end


    def self.import_deletions(json_file)
      result = {success: false, deleted: 0}
      if File.exist?(json_file)
        deleted_json = File.read(json_file)
        deleted_ids = JSON.parse(deleted_json)
        deleted_ids.each do |id|
          obj = Apidae::Object.find_by_apidae_id(id)
          if obj
            obj.destroy!
            result[:deleted] += 1
          else
            puts "skipping object deletion : #{id}"
          end
        end
        result[:success] = true
      end
      result
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

    def self.load_pictures
      Apidae::Object.all.each do |obj|
        if obj.apidae_attached_files.blank? && obj.pictures.any?
          obj.pictures.each do |pic|
            begin
              attached = Apidae::AttachedFile.new(apidae_object_id: id, name: pic[:name], picture: URI.parse(pic[:url]),
                                          description: pic[:description], credits: pic[:credits])
              attached.save
            rescue OpenURI::HTTPError => e
              puts "Could not retrieve attached picture for object #{title} - Error is #{e.message}"
            end
          end
        end
      end
    end

    def self.import_selections(json_file)
      selections_json = File.read(json_file)
      selections_hashes = JSON.parse(selections_json, symbolize_names: true)
      selections_hashes.each do |selection_data|
        Apidae::Selection.add_or_update(selection_data)
      end
      Apidae::Selection.all.collect {|sel| {id: sel.id, apidae_id: sel.apidae_id, reference: sel.reference, objects: sel.objects.count}}
    end
  end
end
