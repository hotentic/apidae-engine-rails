module Apidae
  class Export < ActiveRecord::Base

    PENDING = 'pending'
    COMPLETE = 'complete'
    CANCELLED = 'cancelled'

    validates_presence_of :file_url, :project_id

    # Note : handle reset case
    def self.pending
      where(remote_status: 'SUCCESS', status: PENDING).order(:id)
    end
  end
end
