class DummyUser
  attr_accessor :id

  def initialize(id)
    @id = id
  end
end

DEFAULT_USER = DummyUser.new(1)

Rails.application.config.after_initialize do
  Apidae::ApplicationController.class_eval do
    def dummy_auth
    end

    def dummy_user
      DEFAULT_USER
    end
  end
end
