require_dependency "apidae/application_controller"

module Apidae
  class DashboardController < ApplicationController
    def index
      @objects = Obj.count
      @selections = Selection.count
      @projects = Project.count
      @references = Reference.count
      @last_imports = FileImport.order(id: :desc).take(100)
    end
  end
end
