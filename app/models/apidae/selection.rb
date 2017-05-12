module Apidae
  class Selection < ActiveRecord::Base
    has_and_belongs_to_many :apidae_objects, :class_name => 'Apidae::Object'


  end
end
