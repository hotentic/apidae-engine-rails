module Apidae
  class Project < ActiveRecord::Base
    has_many :apidae_selections, class_name: 'Apidae::Selection', foreign_key: :apidae_project_id
  end
end