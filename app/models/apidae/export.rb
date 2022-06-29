require 'uri'
require 'net/http'

module Apidae
  class Export < ActiveRecord::Base

    PENDING = 'pending'
    IN_PROGRESS = 'in_progress'
    COMPLETE = 'complete'
    CANCELLED = 'cancelled'

    validates_presence_of :file_url, :project_id

    before_save :normalize_url

    def normalize_url
      self.file_url = file_url.strip
      unless file_url.include?('/')
        self.file_url = "http://export.apidae-tourisme.com/exports/#{file_url}"
      end
    end

    # Note : handle reset case
    def self.pending
      where(remote_status: 'SUCCESS', status: PENDING).order(:id)
    end

    def self.in_progress
      where(remote_status: 'SUCCESS', status: IN_PROGRESS)
    end

    def import_data
      success = true
      begin
        open(file_url) do |f|
          begin
            FileImport.import(f, project_id)
            unless confirm_url.blank?
              uri = URI(confirm_url)
              req = Net::HTTP::Post.new(uri)
              Net::HTTP.start(uri.hostname, uri.port) do |http|
                http.request(req)
              end
            end
            update(status: Export::COMPLETE)
            if Rails.application.config.respond_to?(:apidae_import_callback)
              Rails.application.config.apidae_import_callback.call(self)
            end
          rescue Exception => ex
            logger.error("Failed to import export file : #{file_url}")
            logger.error("Error is : #{ex} \n#{ex.backtrace.join("\n") unless ex.backtrace.blank?}")
            success = false
            update(status: Export::CANCELLED)
          end
        end
      rescue OpenURI::HTTPError => err
        logger.error("Failed to download export file : #{file_url}")
        logger.error("Error is : #{err}")
        success = false
        update(status: Export::CANCELLED)
      rescue Exception => e
        logger.error "Failed to import file : #{e.file_url}"
        logger.error("Error is : #{err}")
        success = false
        e.update(status: Export::CANCELLED)
      end
      success
    end
  end
end
