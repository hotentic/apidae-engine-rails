require_dependency "apidae/application_controller"

module Apidae
  class ProjectsController < ApplicationController
    before_action :set_project, only: [:edit, :update]

    def index
      @projects = Project.all
    end

    def new
      session[:referrer] = request.referrer.split('?').first
      @project = Project.new(locales: [DEFAULT_LOCALE])
    end

    def create
      @project = Project.new(project_params)
      if @project.save
        referrer = session.delete(:referrer)
        redirect_to (referrer + "?apidae_project_id=#{@project.id}"), notice: 'Le projet a bien été créé'
      else
        flash.now[:alert] = "Une erreur s'est produite lors la création du projet"
        render :new
      end
    end

    def edit
      session[:referrer] = request.referrer.split('?').first
    end

    def update
      if @project.update(project_params)
        referrer = session.delete(:referrer)
        redirect_to (referrer + "?apidae_project_id=#{@project.id}"), notice: 'Le projet a bien été mis à jour'
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
      params.require(:project).permit(:name, :api_key, :apidae_id, locales: [])
    end
  end
end
