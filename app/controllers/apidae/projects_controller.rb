require_dependency "apidae/application_controller"

module Apidae
  class ProjectsController < ApplicationController
    before_action :set_project, only: [:edit, :update]

    def index
      @projects = Project.all
    end

    def edit
      session[:referrer] = request.referrer
    end

    def update
      if @project.update(project_params)
        referrer = (session.delete(:referrer) || projects_url)
        redirect_to referrer, notice: 'Le projet a bien été mis à jour'
      else
        flash.now[:alert] = "Une erreur s'est produite lors la mise à jour du projet"
        render :edit
      end
    end

    private

    def set_project
      @project = Project.find(params[:id])
    end

    def project_params
      params.require(:project).permit(:name, :api_key)
    end
  end
end
