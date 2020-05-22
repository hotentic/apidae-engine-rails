require_dependency "apidae/application_controller"

module Apidae
  class ObjectsController < ApplicationController
    before_action :set_object, only: [:show, :edit, :update, :destroy, :refresh]
    skip_before_action Rails.application.config.apidae_auth, only: [:index, :show], :if => Proc.new {|c| c.request.format.json?}

    def index
      session[:referrer] = request.referrer
      if params[:selection_id]
        @selection = Selection.find(params[:selection_id])
        @objects = @selection.objects.select(:id, :apidae_id, :title_data, :apidae_type, :updated_at)
      elsif user_is_admin?
        @objects = Obj.all.select(:id, :apidae_id, :title_data, :apidae_type, :updated_at)
      else
        projects_ids = Project.where(apidae_id: apidae_user.apidae_projects_ids).map {|p| p.id}
        @objects = Obj.joins(:selections).where("apidae_selections.apidae_project_id IN (?)", projects_ids)
                     .select("apidae_objs.id, apidae_objs.apidae_id, apidae_objs.title_data, apidae_objs.apidae_type, apidae_objs.updated_at")
                     .distinct("apidae_objs.apidae_id").to_a
      end
    end

    def show
    end

    def new
      @obj = Obj.new
      @selection_apidae_id = params[:selection_apidae_id]
    end

    def edit
    end

    def create
      @obj = Obj.new(object_params)
      if Obj.find_by_apidae_id(@obj.apidae_id)
        redirect_to objects_url, alert: "Cet objet est déjà importé."
      else
        selection = params[:selection_apidae_id].blank? ? Selection.last : Selection.find_by_apidae_id(params[:selection_apidae_id])
        if @obj.save && selection.add_or_refresh_obj(@obj.apidae_id)
          redirect_to objects_url, notice: "L'objet a bien été importé"
        else
          flash[:alert] = "Une erreur s'est produite lors de l'import de l'objet."
          render :new
        end
      end

    end

    def update
      if @obj.update(object_params)
        redirect_to @obj, notice: 'Object was successfully updated.'
      else
        render :edit
      end
    end

    def destroy
      @obj.destroy
      redirect_to objects_url, notice: 'Object was successfully destroyed.'
    end

    def refresh
      referrer = (session.delete(:referrer) || objects_url)
      if @obj && @obj.selections.first.add_or_refresh_obj(@obj.apidae_id)
        redirect_to referrer, notice: "L'objet touristique a bien été mis à jour."
      else
        redirect_to referrer, alert: "Une erreur s'est produite lors de la mise à jour de l'objet."
      end
    end

    private
      def set_object
        @obj = Obj.find(params[:id])
      end

      def object_params
        params.require(:obj).permit!
      end
  end
end
