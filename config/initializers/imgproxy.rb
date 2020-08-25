Imgproxy.configure do |config|
  # imgproxy endpoint
  #
  # Full URL to where your imgproxy lives.
  config.endpoint = ApplicationConfig["IMGPROXY_ENDPOINT"]

  # Next, you have to provide your signature key and salt.
  # If unsure, check out https://github.com/imgproxy/imgproxy/blob/master/docs/configuration.md first.

  # Hex-encoded signature key
  config.hex_key = ApplicationConfig["IMGPROXY_KEY"]
  # Hex-encoded signature salt
  config.hex_salt = ApplicationConfig["IMGPROXY_SALT"]

  # Base64 encode all URLs
  config.base64_encode_urls = true

  # Always escape plain URLs
  # config.always_escape_plain_urls = true
end
