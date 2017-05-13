module Apidae
  class AttachedFile < ActiveRecord::Base
    belongs_to :apidae_object, :class_name => 'Apidae::Object'

    has_attached_file :picture,
                      {
                          :styles => {
                              :xlarge => ['1600x1200>', :jpg],
                              :large => ['1280x960>', :jpg],
                              :medium => ['800x600>', :jpg],
                              :small => ['320x240', :jpg],
                              :thumb => ['200x200>', :png]
                          },
                          :default_url => "/#{Rails.application.config.apidae_pictures_path}/default/logo.png",
                          :path => "public/#{Rails.application.config.apidae_pictures_path}/:apidae_type/:apidae_id/:basename.:extension",
                          :url => "/#{Rails.application.config.apidae_pictures_path}/:apidae_type/:apidae_id/:basename.:extension"
                      }

    validates_attachment :picture, content_type: { content_type: /\Aimage\/.*\Z/ }

    private

    Paperclip.interpolates :apidae_type do |attachment, style|
      attachment.instance.apidae_object.apidae_type.downcase
    end

    Paperclip.interpolates :apidae_id do |attachment, style|
      attachment.instance.apidae_object.apidae_id
    end
  end
end
