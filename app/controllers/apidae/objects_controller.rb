require_dependency "apidae/application_controller"

module Apidae
  class ObjectsController < ApplicationController
    before_action :set_object, only: [:show, :edit, :update, :destroy, :refresh]
    skip_before_action Rails.application.config.apidae_auth, only: [:index, :show]

    def index
      session[:referrer] = request.referrer
      if params[:selection_id]
        @selection = Selection.find(params[:selection_id])
        @objects = @selection.objects.select(:id, :apidae_id, :title, :apidae_type, :updated_at)
      else
        @objects = Obj.all.select(:id, :apidae_id, :title, :apidae_type, :updated_at)
      end
    end

    def show
    end

    def new
      @object = Obj.new
    end

    def edit
    end

    def create
      @object = Obj.new(object_params)

      if @object.save
        redirect_to @object, notice: 'Object was successfully created.'
      else
        render :new
      end
    end

    def update
      if @object.update(object_params)
        redirect_to @object, notice: 'Object was successfully updated.'
      else
        render :edit
      end
    end

    def destroy
      @object.destroy
      redirect_to objects_url, notice: 'Object was successfully destroyed.'
    end

    def refresh
      referrer = session.delete(:referrer)
      if @object && @object.selections.first.refresh_obj(@object.apidae_id)
        redirect_to referrer, notice: "L'objet touristique a bien été mis à jour."
      else
        redirect_to referrer, alert: "Une erreur s'est produite lors de la mise à jour de l'objet."
      end
    end

    private
      def set_object
        @object = Obj.find(params[:id])
      end

      def object_params
        params.require(:object).permit!
      end
  end
end
