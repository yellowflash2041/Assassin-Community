# rubocop:disable Metrics/BlockLength
Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # Code is not reloaded between requests.
  config.cache_classes = true

  # Eager load code on boot. This eager loads most of Rails and
  # your application in memory, allowing both threaded web servers
  # and those relying on copy on write to perform better.
  # Rake tasks automatically ignore this option for performance.
  config.eager_load = true

  # Full error reports are disabled and caching is turned on.
  config.consider_all_requests_local       = false
  config.action_controller.perform_caching = true

  # Ensures that a master key has been made available in either ENV["RAILS_MASTER_KEY"]
  # or in config/master.key. This key is used to decrypt credentials (and other encrypted files).
  # config.require_master_key = true

  # Attempt to read encrypted secrets from `config/secrets.yml.enc`.
  # Requires an encryption key in `ENV["RAILS_MASTER_KEY"]` or
  # `config/secrets.yml.key`.
  config.read_encrypted_secrets = true

  # Disable serving static files from the `/public` folder by default since
  # Apache or NGINX already handles this.
  config.public_file_server.enabled = ENV["RAILS_SERVE_STATIC_FILES"].present?
  config.public_file_server.headers = {
    "Cache-Control" => "public, s-maxage=#{30.days.to_i}, max-age=#{30.days.to_i}"
  }

  # Compress JavaScripts and CSS.
  config.assets.js_compressor = :uglify_with_source_maps
  # config.assets.css_compressor = :sass

  # Do not fallback to assets pipeline if a precompiled asset is missed.
  config.assets.compile = true

  # `config.assets.precompile` and `config.assets.version` have moved to config/initializers/assets.rb
  config.assets.digest = true

  # Enable serving of images, stylesheets, and JavaScripts from an asset server.
  config.action_controller.asset_host = ENV["FASTLY_CDN_URL"]

  # Specifies the header that your server uses for sending files.
  # config.action_dispatch.x_sendfile_header = 'X-Sendfile' # for Apache
  # config.action_dispatch.x_sendfile_header = 'X-Accel-Redirect' # for NGINX

  # Store uploaded files on the local file system (see config/storage.yml for options)
  # config.active_storage.service = :local

  # Force all access to the app over SSL, use Strict-Transport-Security, and use secure cookies.
  config.force_ssl = ENV["FORCE_SSL_IN_RAILS"] == "true"

  # Use the lowest log level to ensure availability of diagnostic information
  # when problems arise.
  config.log_level = ENV["LOG_LEVEL"] || :error

  # Prepend all log lines with the following tags.
  config.log_tags = [:request_id]

  # Use a different cache store in production.
  # DEV uses the RedisCloud Heroku Add-On which comes with the predefined env variable REDISCLOUD_URL
  redis_url = ENV["REDISCLOUD_URL"]
  redis_url ||= ENV["REDIS_URL"]
  DEFAULT_EXPIRATION = 24.hours.to_i.freeze
  config.cache_store = :redis_cache_store, { url: redis_url, expires_in: DEFAULT_EXPIRATION }

  # Use a real queuing backend for Active Job (and separate queues per environment)
  # config.active_job.queue_adapter     = :resque
  # config.active_job.queue_name_prefix = "practical_developer_#{Rails.env}"

  config.action_mailer.perform_caching = false

  # Ignore bad email addresses and do not raise email delivery errors.
  # Set this to true and configure the email server for immediate delivery to raise delivery errors.
  # config.action_mailer.raise_delivery_errors = false

  # Enable locale fallbacks for I18n (makes lookups for any locale fall back to
  # the I18n.default_locale when a translation cannot be found).
  config.i18n.fallbacks = true

  # Send deprecation notices to registered listeners.
  config.active_support.deprecation = :notify

  # Filter sensitive information from production logs
  config.filter_parameters += %i[
    auth_data_dump content email encrypted
    encrypted_password message_html message_markdown
    password previous_refresh_token refresh_token secret
    to token current_sign_in_ip last_sign_in_ip
    reset_password_token remember_token unconfirmed_email
  ]

  # Use default logging formatter so that PID and timestamp are not suppressed.
  config.log_formatter = ::Logger::Formatter.new

  if ENV["RAILS_LOG_TO_STDOUT"].present?
    # Use a different logger for distributed setups.
    # require 'syslog/logger'
    # config.logger = ActiveSupport::TaggedLogging.new(Syslog::Logger.new 'app-name')

    logger           = ActiveSupport::Logger.new($stdout)
    logger.formatter = config.log_formatter
    config.logger    = ActiveSupport::TaggedLogging.new(logger)
  end

  # Do not dump schema after migrations.
  config.active_record.dump_schema_after_migration = false

  config.app_domain = ENV["APP_DOMAIN"] || "localhost:3000"
  protocol = ENV["APP_PROTOCOL"] || "http://"

  config.action_mailer.delivery_method = :smtp
  config.action_mailer.perform_deliveries = true
  sendgrid_api_key_present = ENV["SENDGRID_API_KEY"].present?
  config.action_mailer.default_url_options = { host: protocol + config.app_domain }
  ActionMailer::Base.smtp_settings = {
    address: "smtp.sendgrid.net",
    port: "587",
    authentication: :plain,
    user_name: sendgrid_api_key_present ? "apikey" : ENV["SENDGRID_USERNAME_ACCEL"],
    password: sendgrid_api_key_present ? ENV["SENDGRID_API_KEY"] : ENV["SENDGRID_PASSWORD_ACCEL"],
    domain: ENV["APP_DOMAIN"],
    enable_starttls_auto: true
  }

  if ENV["HEROKU_APP_URL"].present? && ENV["HEROKU_APP_URL"] != config.app_domain
    config.middleware.use Rack::HostRedirect,
                          ENV["HEROKU_APP_URL"] => config.app_domain
  end
end
# rubocop:enable Metrics/BlockLength

Rails.application.routes.default_url_options = {
  host: Rails.application.config.app_domain,
  protocol: (ENV["APP_PROTOCOL"] || "http://").delete_suffix("://")
}
