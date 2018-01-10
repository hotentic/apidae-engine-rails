require_dependency "apidae/application_controller"

module Apidae
  class ObjectsController < ApplicationController
    before_action :set_object, only: [:show, :edit, :update, :destroy]

    # GET /objects
    def index
      @objects = Object.all.select(:apidae_id, :title, :apidae_type, :updated_at)
    end

    # GET /objects/1
    def show
    end

    # GET /objects/new
    def new
      @object = Object.new
    end

    # GET /objects/1/edit
    def edit
    end

    # POST /objects
    def create
      @object = Object.new(object_params)

      if @object.save
        redirect_to @object, notice: 'Object was successfully created.'
      else
        render :new
      end
    end

    # PATCH/PUT /objects/1
    def update
      if @object.update(object_params)
        redirect_to @object, notice: 'Object was successfully updated.'
      else
        render :edit
      end
    end

    # DELETE /objects/1
    def destroy
      @object.destroy
      redirect_to objects_url, notice: 'Object was successfully destroyed.'
    end

    private
      # Use callbacks to share common setup or constraints between actions.
      def set_object
        @object = Object.find(params[:id])
      end

      # Only allow a trusted parameter "white list" through.
      def object_params
        params.require(:object).permit(:address, :apidae_id, :apidae_type, :apidae_subtype, :title, :short_desc, :contact, :long_desc, :type_data, :latitude, :longitude, :openings, :rates, :reservation)
      end
  end
end
