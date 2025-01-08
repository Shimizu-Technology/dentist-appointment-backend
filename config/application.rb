require_relative "boot"

# Remove Rails/all and require only the frameworks you need:
require "active_model/railtie"
require "active_job/railtie"
require "active_record/railtie"
require "action_controller/railtie"
require "action_mailer/railtie"
# require "sprockets/railtie"  # Uncomment only if you need the asset pipeline
# require "rails/test_unit/railtie"

Bundler.require(*Rails.groups)

module DentistAppointmentBackend
  class Application < Rails::Application
    config.load_defaults 7.2

    config.time_zone = "Pacific/Guam"

    # ----------------------------------------------------------------------------
    # 1) We read ENV['FRONTEND_URL'] or default to "http://localhost:5173".
    #    Then we store it in config.x.frontend_url so that mailers (and others)
    #    can reference it via Rails.application.config.x.frontend_url.
    # ----------------------------------------------------------------------------
    config.x.frontend_url = ENV.fetch("FRONTEND_URL", "http://localhost:5173")

    # ...
  end
end
