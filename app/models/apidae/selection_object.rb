module Apidae
  class SelectionObject < ApplicationRecord
    belongs_to :apidae_object, class_name: 'Apidae::Object', foreign_key: :apidae_object_id
    belongs_to :apidae_selection, class_name: 'Apidae::Selection', foreign_key: :apidae_selection_id
  end
end
