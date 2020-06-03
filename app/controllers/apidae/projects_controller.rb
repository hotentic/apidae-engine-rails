require_dependency "apidae/application_controller"

module Apidae
  class ProjectsController < ApplicationController
    before_action :set_project, only: [:edit, :update, :destroy]
    skip_before_action :check_user_data!, only: [:create]

    def index
      if user_is_admin?
        @projects = Project.all
      else
        @projects = Project.where(apidae_id: apidae_user.apidae_projects_ids)
      end
    end

    def new
      session[:referrer] = request.referrer.split('?').first unless request.referrer.blank?
      @project = Project.new(locales: [DEFAULT_LOCALE], versions: [DEFAULT_VERSION])
    end

    def create
      if Project.find_by_apidae_id(project_params[:apidae_id])
        @project = Project.find_by_apidae_id(project_params[:apidae_id])
        update_project
      else
        @project = Project.new(project_params)
        if @project.save
          referrer = params[:redirect_to] || session.delete(:referrer) || projects_url
          redirect_to (referrer + "?apidae_project_id=#{@project.id}"), notice: 'Le projet a bien été créé'
        else
          flash.now[:alert] = "Une erreur s'est produite lors la création du projet"
          render :new
        end
      end
    end

    def edit
      session[:referrer] = request.referrer.split('?').first unless request.referrer.blank?
    end

    def update
      update_project
    end

    def destroy
      @project.destroy
      redirect_to request.referrer, notice: 'Le projet a bien été supprimé.'
    end

    private

    def set_project
      @project = Project.find(params[:id])
    end

    def update_project
      if @project.update(project_params)
        referrer = params[:redirect_to] || session.delete(:referrer)
        redirect_to (referrer + "?apidae_project_id=#{@project.id}"), notice: 'Le projet a bien été mis à jour'
      else
        flash.now[:alert] = "Une erreur s'est produite lors la mise à jour du projet"
        render :edit
      end
    end

    def project_params
      params.require(:project).permit(:name, :api_key, :apidae_id, locales: [], versions: [])
    end
  end
end
