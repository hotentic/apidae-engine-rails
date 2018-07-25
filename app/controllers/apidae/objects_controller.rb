require_dependency "apidae/application_controller"

module Apidae
  class ObjectsController < ApplicationController
    before_action :set_object, only: [:show, :edit, :update, :destroy]
    skip_before_action Rails.application.config.apidae_auth, only: [:index, :show]

    def index
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

    private
      def set_object
        @object = Obj.find(params[:id])
      end

      def object_params
        params.require(:object).permit!
      end
  end
end
