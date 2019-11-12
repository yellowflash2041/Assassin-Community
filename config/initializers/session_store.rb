# Be sure to restart your server when you modify this file.

# we want a default in case the expiration is not set or set to 0
# because 0 is an invalid value
app_config_expires_after = ApplicationConfig["SESSION_EXPIRY_SECONDS"].to_i
expires_after = app_config_expires_after.positive? ? app_config_expires_after : 2.weeks.to_i

# see <https://github.com/redis-store/redis-rails#session-storage> for configuration options,
# httponly has been added in <https://github.com/redis-store/redis-actionpack/pull/17>
Rails.application.config.session_store :redis_store,
                                       key: ApplicationConfig["SESSION_KEY"],
                                       servers: ApplicationConfig["REDIS_URL"],
                                       expire_after: expires_after,
                                       signed: true,
                                       secure: Rails.env.production?,
                                       httponly: true
