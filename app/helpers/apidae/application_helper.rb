module Apidae
  module ApplicationHelper
    include ApidaeHelper

    def apidae_user
      send(Rails.application.config.apidae_user) if Rails.application.config.respond_to?(:apidae_user)
    end
  end
end
