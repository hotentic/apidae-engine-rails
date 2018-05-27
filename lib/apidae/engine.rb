module Apidae
  class Engine < Rails::Engine
    isolate_namespace Apidae
    # Include all helpers from main app
    config.to_prepare do
      ApplicationController.helper(ActionView::Helpers::ApplicationHelper)
    end
  end
end
