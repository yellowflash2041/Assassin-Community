# Timber.io Ruby Configuration - Simple Structured Logging
#
#  ^  ^  ^   ^      ___I_      ^  ^   ^  ^  ^   ^  ^
# /|\/|\/|\ /|\    /\-_--\    /|\/|\ /|\/|\/|\ /|\/|\
# /|\/|\/|\ /|\   /  \_-__\   /|\/|\ /|\/|\/|\ /|\/|\
# /|\/|\/|\ /|\   |[]| [] |   /|\/|\ /|\/|\/|\ /|\/|\
# -------------------------------------------------------------------
# Website:       https://timber.io
# Documentation: https://timber.io/docs
# Support:       support@timber.io
# -------------------------------------------------------------------

config = Timber::Config.instance
config.integrations.action_view.silence = true
config.integrations.active_record.silence = !Rails.env.development?
config.integrations.rack.http_events.collapse_into_single_event = true

config.integrations.rack.http_events.silence_request = lambda do |_rack_env, rack_request|
  rack_request.path.match?(/^\/page_views\/\d{1,9}/)
end

# Add additional configuration here.
# For a full list of configuration options and their explanations see:
# http://www.rubydoc.info/github/timberio/timber-ruby/Timber/Config
