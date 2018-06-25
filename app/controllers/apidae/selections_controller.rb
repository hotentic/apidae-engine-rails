require_dependency "apidae/application_controller"

module Apidae
  class SelectionsController < ApplicationController
    before_action :set_selection, only: [:show, :edit, :update, :destroy]

    def index
      @selections = Selection.all
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

    private
      def set_selection
        @selection = Selection.find(params[:id])
      end

      def selection_params
        params.require(:selection).permit(:label, :reference, :apidae_id)
      end
  end
end
