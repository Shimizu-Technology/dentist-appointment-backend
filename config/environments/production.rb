# File: config/environments/production.rb
require "active_support/core_ext/integer/time"

Rails.application.configure do
  # ----------------------------------------------------------------------------
  # Basic Production Essentials
  # ----------------------------------------------------------------------------

  # In production, we typically do NOT reload code on every request
  config.enable_reloading = false

  # Eager load code on boot for performance
  config.eager_load = true

  # Usually you want to show minimal error info to the public
  config.consider_all_requests_local = false

  # Enable caching (frequently desired in production)
  config.action_controller.perform_caching = true

  # Log to STDOUT (especially for Heroku or Docker)
  config.logger = ActiveSupport::Logger.new(STDOUT)
    .tap  { |logger| logger.formatter = ::Logger::Formatter.new }
    .then { |logger| ActiveSupport::TaggedLogging.new(logger) }

  # Prepend all log lines with the following tags.
  config.log_tags = [:request_id]

  # Typically set to :info or :warn in production
  config.log_level = ENV.fetch("RAILS_LOG_LEVEL", "info")

  # If you want to enforce SSL in production, uncomment:
  # config.force_ssl = true

  # ----------------------------------------------------------------------------
  # Production “Mail” Configuration (mirroring dev’s SendGrid setup)
  # ----------------------------------------------------------------------------

  # Raise errors if the mailer can’t send (useful to see problems in logs)
  config.action_mailer.raise_delivery_errors = true

  # Use the same SMTP-based delivery method as dev
  config.action_mailer.delivery_method = :smtp

  config.action_mailer.smtp_settings = {
    user_name:             'apikey',               # SendGrid requirement
    password:              ENV['SENDGRID_API_KEY'],# Must be set in your environment
    domain:                'gmail.com',            # or another domain
    address:               'smtp.sendgrid.net',
    port:                  587,
    authentication:        :plain,
    enable_starttls_auto:  true
  }

  # In production, you typically need a real host domain (or IP).
  # If you don’t have one, just set to your ephemeral domain, e.g. "myapp.onrender.com".
  config.action_mailer.default_url_options = {
    host: 'my-production-domain.com',
    protocol: 'https'
  }

  # If you want the “from” address to match your domain, you can override it at the Mailer level
  # or here with default_options:
  # config.action_mailer.default_options = {
  #   from: 'YourDentalApp <no-reply@my-production-domain.com>'
  # }

  # ----------------------------------------------------------------------------
  # Additional Production Stuff
  # ----------------------------------------------------------------------------

  # i18n fallback
  config.i18n.fallbacks = true

  # Don’t log any deprecations in production
  config.active_support.report_deprecations = false

  # etc… (any other default production settings you need)

end
