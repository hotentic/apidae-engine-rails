module Apidae
  class ApplicationRecord < ActiveRecord::Base
    self.abstract_class = true
  end
end
