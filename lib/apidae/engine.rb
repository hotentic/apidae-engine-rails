module Apidae
  class Engine < Rails::Engine
    isolate_namespace Apidae
    # Include all helpers from main app
    config.to_prepare do
      ApplicationController.helper(ActionView::Helpers::ApplicationHelper)
      Dir.glob(Rails.root + "app/decorators/**/*_decorator*.rb").each do |c|
        require_dependency(c)
      end
    end
  end
end
