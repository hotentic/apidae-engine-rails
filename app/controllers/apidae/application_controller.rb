module Apidae
  class ApplicationController < ActionController::Base
    protect_from_forgery with: :exception
    before_action Rails.application.config.apidae_auth
    before_action :check_user_data!

    def apidae_user
      send(Rails.application.config.apidae_user) if Rails.application.config.respond_to?(:apidae_user)
    end

    def user_is_admin?
      apidae_user && Rails.application.config.respond_to?(:apidae_admin) && Rails.application.config.apidae_admin.call(apidae_user)
    end

    def user_has_data?
      apidae_user && apidae_user.respond_to?(:apidae_projects_ids) && !apidae_user.apidae_projects_ids.blank?
    end

    def check_user_data!
      unless user_has_data? || user_is_admin?
        redirect_to main_app.root_path, alert: "Il n'y a aucun projet Apidae associé à votre compte."
      end
    end
  end
end
