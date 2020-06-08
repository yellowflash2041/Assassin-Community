# rubocop:disable Metrics/BlockLength
# Silence all Ruby 2.7 deprecation warnings
$VERBOSE = nil

Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # In the development environment your application's code is reloaded on
  # every request. This slows down response time but is perfect for development
  # since you don't have to restart the web server when you make code changes.
  config.cache_classes = false

  # Do not eager load code on boot.
  config.eager_load = false

  # Show full error reports.
  config.consider_all_requests_local = true

  # Enable/disable caching. By default caching is disabled.
  # Run rails dev:cache to toggle caching.
  if Rails.root.join("tmp/caching-dev.txt").exist?
    config.action_controller.perform_caching = true

    DEFAULT_EXPIRATION = 1.hour.to_i.freeze
    config.cache_store = :redis_cache_store, { url: ENV["REDIS_URL"], expires_in: DEFAULT_EXPIRATION }

    config.public_file_server.headers = {
      "Cache-Control" => "public, max-age=#{2.days.to_i}"
    }
  else
    config.action_controller.perform_caching = false

    config.cache_store = :null_store
  end

  # Store uploaded files on the local file system (see config/storage.yml for options)
  # config.active_storage.service = :local

  # Don't care if the mailer can't send.
  config.action_mailer.raise_delivery_errors = false

  config.action_mailer.perform_caching = false

  # Print deprecation notices to the Rails logger.
  config.active_support.deprecation = :log

  # Raise an error on page load if there are pending migrations.
  config.active_record.migration_error = :page_load

  # Highlight code that triggered database queries in logs.
  config.active_record.verbose_query_logs = true

  # Allows setting a warning threshold for query result size.
  # If the number of records returned by a query exceeds the threshold, a warning is logged.
  # This can be used to identify queries which might be causing a memory bloat.
  config.active_record.warn_on_records_fetched_greater_than = 1500

  # Debug mode disables concatenation and preprocessing of assets.
  # This option may cause significant delays in view rendering with a large
  # number of complex assets.
  config.assets.debug = false

  # Asset digests allow you to set far-future HTTP expiration dates on all assets,
  # yet still be able to expire them through the digest params.
  config.assets.digest = false

  # Suppress logger output for asset requests.
  config.assets.quiet = true

  # Adds additional error checking when serving assets at runtime.
  # Checks for improperly declared sprockets dependencies.
  # Raises helpful error messages.
  config.assets.raise_runtime_errors = true

  config.action_mailer.perform_caching = false

  config.hosts << ENV["APP_DOMAIN"] unless ENV["APP_DOMAIN"].nil?
  config.app_domain = "localhost:3000"

  config.action_mailer.default_url_options = { host: "localhost:3000" }
  config.action_mailer.delivery_method = :smtp
  config.action_mailer.perform_deliveries = true
  config.action_mailer.default_url_options = { host: config.app_domain }
  config.action_mailer.smtp_settings = {
    address: "smtp.gmail.com",
    port: "587",
    enable_starttls_auto: true,
    user_name: '<%= ENV["DEVELOPMENT_EMAIL_USERNAME"] %>',
    password: '<%= ENV["DEVELOPMENT_EMAIL_PASSWORD"] %>',
    authentication: :plain,
    domain: "localhost:3000"
  }

  config.action_mailer.preview_path = Rails.root.join("spec/mailers/previews")

  # Raises error for missing translations
  # config.action_view.raise_on_missing_translations = true

  config.public_file_server.enabled = true

  # Use an evented file watcher to asynchronously detect changes in source code,
  # routes, locales, etc. This feature depends on the listen gem.
  config.file_watcher = ActiveSupport::EventedFileUpdateChecker

  # Debug is the default log_level, but can be changed per environment.
  config.log_level = :debug

  if ENV["RAILS_LOG_TO_STDOUT"].present?
    logger           = ActiveSupport::Logger.new(STDOUT)
    logger.formatter = config.log_formatter
    config.logger    = ActiveSupport::TaggedLogging.new(logger)
  end

  config.after_initialize do
    # See <https://github.com/flyerhzm/bullet#configuration> for other Bullet config options
    Bullet.enable = true

    Bullet.add_footer = true
    Bullet.console = true
    Bullet.rails_logger = true

    Bullet.add_whitelist(type: :unused_eager_loading, class_name: "ApiSecret", association: :user)
    # acts-as-taggable-on has super weird eager loading problems: <https://github.com/mbleigh/acts-as-taggable-on/issues/91>
    Bullet.add_whitelist(type: :n_plus_one_query, class_name: "ActsAsTaggableOn::Tagging", association: :tag)
    # Supress incorrect warnings from Bullet due to included columns: https://github.com/flyerhzm/bullet/issues/147
    Bullet.add_whitelist(type: :unused_eager_loading, class_name: "Article", association: :top_comments)
    Bullet.add_whitelist(type: :unused_eager_loading, class_name: "Comment", association: :user)

    # Check if there are any data update scripts to run during startup
    if %w[c console runner s server].include?(ENV["COMMAND"])
      if DataUpdateScript.scripts_to_run?
        raise "Data update scripts need to be run before you can start the application. Please run 'rails data_updates:run'"
      end
    end
  end
end

Rails.application.routes.default_url_options = { host: Rails.application.config.app_domain }
# rubocop:enable Metrics/BlockLength
