module Apidae
  class ApplicationController < ActionController::Base
    protect_from_forgery with: :exception
    before_action Rails.application.config.apidae_auth
  end
end
