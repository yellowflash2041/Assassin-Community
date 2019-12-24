# Can be used to implement more programatic error handling
# https://docs.honeybadger.io/lib/ruby/getting-started/ignoring-errors.html#ignore-programmatically

Honeybadger.configure do |config|
  config.api_key = ApplicationConfig["HONEYBADGER_API_KEY"]
  config.revision = ApplicationConfig["HEROKU_SLUG_COMMIT"]
  config.exceptions.ignore += [
    Pundit::NotAuthorizedError,
    ActiveRecord::RecordNotFound,
    ActiveRecord::QueryCanceled,
  ]
  config.request.filter_keys += %w[authorization]
  config.delayed_job.attempt_threshold = 10

  config.before_notify do |notice|
    notice.fingerprint = if notice.error_message&.include?("SIGTERM") && notice.component&.include?("fetch_all_rss")
                           notice.error_message
                         elsif notice.error_message&.include?("BANNED")
                           "banned"
                         elsif notice.error_message&.include?("Rack::Timeout::RequestTimeoutException")
                           "rack_timeout"
                         elsif notice.component&.include?("internal")
                           "internal"
                         end
  end
end
