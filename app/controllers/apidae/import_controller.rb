require_dependency "apidae/application_controller"
require 'uri'
require 'net/http'

module Apidae
  class ImportController < ApplicationController
    skip_before_action :verify_authenticity_token

    # Callback endpoint for Apidae exports
    #
    # projetId : un entier. C’est l’identifiant du projet concerné.
    # statut : une chaine de caractères, ‘SUCCESS’ ou ‘ERROR’. C’est l’issue de l’export.
    # ponctuel : un booléen. Indique si l’export est ponctuel (true) ou périodique (false).
    # reinitialisation : un booléen. Indique si l’export est une réinitialisation (true) ou différentiel (false).
    # urlRecuperation : une chaine de caractères. L’URL de récupération du fichier d’export.
    # urlConfirmation : une chaine de caractères. L’URL de confirmation.
    def callback
      project_id = params[:projetId]
      if project_id == Rails.application.config.apidae_project_id
        export = Export.new(project_id: project_id, remote_status: params[:statut], oneshot: params[:ponctuel] == 'true',
                            reset: params[:reinitialisation] == 'true', file_url: params[:urlRecuperation],
                            confirm_url: params[:urlConfirmation], status: Export::PENDING)
        if export.save
          render nothing: true, status: :ok
        else
          render nothing: true, status: :internal_server_error
        end
      else
        render nothing: true, status: :not_found
      end
    end

    def run
      success = true
      Export.pending.each do |e|
        open(e.file_url) do |f|
          begin
            FileImport.import(f)
            uri = URI(e.confirm_url)
            req = Net::HTTP::Post.new(uri)
            Net::HTTP.start(uri.hostname, uri.port) do |http|
              http.request(req)
            end
            e.update(status: Export::COMPLETE)
          rescue Exception => ex
            logger.error("Failed to retrieve export file : #{ex.file_url}")
            logger.error("Error is : #{ex}")
            success = false
          end
        end
      end
      render nothing: true, status: (success ? :ok : :internal_server_error)
    end
  end
end
