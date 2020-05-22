require_dependency "apidae/application_controller"

module Apidae
  class SelectionsController < ApplicationController
    before_action :set_selection, only: [:show, :edit, :update, :destroy, :refresh]

    def index
      if user_is_admin?
        @selections = Selection.all
      else
        projects_ids = Project.where(apidae_id: apidae_user.apidae_projects_ids).map {|p| p.id}
        @selections = Selection.where(apidae_project_id: projects_ids)
      end
    end

    def show
    end

    def new
      @selection = Selection.new
    end

    def edit
    end

    def create
      @selection = Selection.new(selection_params)

      if @selection.save
        redirect_to @selection, notice: 'Selection was successfully created.'
      else
        render :new
      end
    end

    def update
      if @selection.update(selection_params)
        redirect_to @selection, notice: 'Selection was successfully updated.'
      else
        render :edit
      end
    end

    def destroy
      @selection.destroy
      redirect_to selections_url, notice: 'Selection was successfully destroyed.'
    end

    def refresh
      referrer = (session.delete(:referrer) || selections_url)
      if @selection && @selection.add_or_refresh_objs
        redirect_to referrer, notice: "La sélection a bien été mise à jour."
      else
        redirect_to referrer, alert: "Une erreur s'est produite lors de la mise à jour de la sélection."
      end
    end

    private
      def set_selection
        @selection = Selection.find(params[:id])
      end

      def selection_params
        params.require(:selection).permit(:label, :reference, :apidae_id)
      end
  end
end
