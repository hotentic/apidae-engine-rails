module Apidae
  class Export < ActiveRecord::Base

    PENDING = 'pending'
    COMPLETE = 'complete'

    # Note : handle reset case
    def self.pending
      where(remote_status: 'SUCCESS', status: PENDING).order(:id)
    end
  end
end
