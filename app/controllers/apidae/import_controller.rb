require_dependency "apidae/application_controller"
require 'uri'
require 'net/http'

module Apidae
  class ImportController < ApplicationController
    skip_before_action :verify_authenticity_token
    skip_before_action Rails.application.config.apidae_auth

    # Callback endpoint for Apidae exports
    #
    # projetId : un entier. C’est l’identifiant du projet concerné.
    # statut : une chaine de caractères, ‘SUCCESS’ ou ‘ERROR’. C’est l’issue de l’export.
    # ponctuel : un booléen. Indique si l’export est ponctuel (true) ou périodique (false).
    # reinitialisation : un booléen. Indique si l’export est une réinitialisation (true) ou différentiel (false).
    # urlRecuperation : une chaine de caractères. L’URL de récupération du fichier d’export.
    # urlConfirmation : une chaine de caractères. L’URL de confirmation.
    def callback
      export = Export.new(project_id: params[:projetId], remote_status: params[:statut], oneshot: params[:ponctuel] == 'true',
                          reset: params[:reinitialisation] == 'true', file_url: params[:urlRecuperation],
                          confirm_url: params[:urlConfirmation], status: Export::PENDING)
      if export.save
        if Rails.application.config.respond_to?(:apidae_propagate_callback)
          uri = URI(Rails.application.config.apidae_propagate_callback)
          req = Net::HTTP::Post.new(uri)
          Net::HTTP.start(uri.hostname, uri.port, use_ssl: (uri.scheme == "https")) do |http|
            http.request(req, params.to_unsafe_h.to_query)
          end
        end
        head :ok
      else
        head :internal_server_error
      end
    end

    def run
      success = true
      Export.pending.each do |e|
        begin
          open(e.file_url) do |f|
            begin
              FileImport.import(f, e.project_id)
              uri = URI(e.confirm_url)
              req = Net::HTTP::Post.new(uri)
              Net::HTTP.start(uri.hostname, uri.port) do |http|
                http.request(req)
              end
              e.update(status: Export::COMPLETE)
              if Rails.application.config.respond_to?(:apidae_import_callback)
                Rails.application.config.apidae_import_callback.call(e)
              end
            rescue Exception => ex
              logger.error("Failed to import export file : #{e.file_url}")
              logger.error("Error is : #{ex} \n#{ex.backtrace.join("\n") unless ex.backtrace.blank?}")
              success = false
              e.update(status: Export::CANCELLED)
            end
          end
        rescue OpenURI::HTTPError => err
          logger.error("Failed to download export file : #{e.file_url}")
          logger.error("Error is : #{err}")
          success = false
          e.update(status: Export::CANCELLED)
        end
      end
      success ? head(:ok) : head(:internal_server_error)
    end
  end
end
