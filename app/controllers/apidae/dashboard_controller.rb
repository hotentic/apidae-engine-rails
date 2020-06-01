require_dependency "apidae/application_controller"

module Apidae
  class DashboardController < ApplicationController
    def index
      if user_is_admin?
        @objects = Obj.count
        @selections = Selection.count
        @projects = Project.count
        @last_imports = FileImport.order(id: :desc).take(100)
      else
        projects = Project.where(apidae_id: apidae_user.apidae_projects_ids)
        selections = Selection.where(apidae_project_id: projects.select(:id).map {|p| p.id})
        @projects = projects.count
        @selections = selections.uniq.count
        @objects = SelectionObject.where(apidae_selection_id: selections.map {|s| s.id}.uniq).map {|so| so.apidae_object_id}.uniq.count
        @last_imports = FileImport.where(apidae_id: apidae_user.apidae_projects_ids).order(id: :desc).take(100)
      end
    end
  end
end
