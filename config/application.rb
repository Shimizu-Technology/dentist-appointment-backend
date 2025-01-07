require_relative "boot"

# Remove Rails/all and require only needed frameworks:
# require "rails/all"
# Instead, require only the frameworks you need, for example:
require "active_model/railtie"
require "active_job/railtie"
require "active_record/railtie"
require "action_controller/railtie"
require "action_mailer/railtie"
# require "sprockets/railtie"  # remove if you don't need asset pipeline
# require "rails/test_unit/railtie"

Bundler.require(*Rails.groups)

module DentistAppointmentBackend
  class Application < Rails::Application
    config.load_defaults 7.2

    config.time_zone = "Pacific/Guam"

    # ...
  end
end
