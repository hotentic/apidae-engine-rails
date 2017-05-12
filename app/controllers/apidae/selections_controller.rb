require_dependency "apidae/application_controller"

module Apidae
  class SelectionsController < ApplicationController
    before_action :set_selection, only: [:show, :edit, :update, :destroy]

    # GET /selections
    def index
      @selections = Selection.all
    end

    # GET /selections/1
    def show
    end

    # GET /selections/new
    def new
      @selection = Selection.new
    end

    # GET /selections/1/edit
    def edit
    end

    # POST /selections
    def create
      @selection = Selection.new(selection_params)

      if @selection.save
        redirect_to @selection, notice: 'Selection was successfully created.'
      else
        render :new
      end
    end

    # PATCH/PUT /selections/1
    def update
      if @selection.update(selection_params)
        redirect_to @selection, notice: 'Selection was successfully updated.'
      else
        render :edit
      end
    end

    # DELETE /selections/1
    def destroy
      @selection.destroy
      redirect_to selections_url, notice: 'Selection was successfully destroyed.'
    end

    private
      # Use callbacks to share common setup or constraints between actions.
      def set_selection
        @selection = Selection.find(params[:id])
      end

      # Only allow a trusted parameter "white list" through.
      def selection_params
        params.require(:selection).permit(:label, :reference, :apidae_id)
      end
  end
end
