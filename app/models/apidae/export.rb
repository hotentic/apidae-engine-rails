module Apidae
  class Export < ActiveRecord::Base

    PENDING = 'pending'
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
  end
end
