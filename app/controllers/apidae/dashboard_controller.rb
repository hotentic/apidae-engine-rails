require_dependency "apidae/application_controller"

module Apidae
  class DashboardController < ApplicationController
    def index
      @objects = Apidae::Object.count
      @selections = Apidae::Selection.count
      @last_imports = Apidae::FileImport.order(id: :desc).take(5)
    end
  end
end
