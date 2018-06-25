require_dependency "apidae/application_controller"

module Apidae
  class ReferencesController < ApplicationController
    def index
      @references = Reference.all
    end
  end
end
