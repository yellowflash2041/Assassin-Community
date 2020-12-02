# This service encapsulates the logic related to validating if reCAPTCHA is
# enabled in the current Forem instance. The decision is based on making
# sure the necessary SiteConfig keys are available and also on the user
# object passed in.
#
# Example use: ReCaptcha::CheckEnabled.call(current_user) => true/false
module ReCaptcha
  class CheckEnabled
    def self.call(user = nil)
      new(user).call
    end

    def initialize(user)
      @user = user
    end

    def call
      # recaptcha will not be enabled if site key and secret key aren't set
      return false unless keys_configured?
      # recaptcha will always be enabled when not logged in
      return true if @user.nil?
      # recaptcha will not be enabled for tag moderator/trusted/admin users
      return false if @user.tag_moderator? || @user.trusted || @user.any_admin?
      # recaptcha will be enabled if the user has been banned
      return true if @user.banned

      # recaptcha will be enabled if the user has a vomit or is too recent
      @user.vomitted_on? || @user.created_at.after?(1.month.ago)
    end

    private

    def keys_configured?
      SiteConfig.recaptcha_site_key.present? && SiteConfig.recaptcha_secret_key.present?
    end
  end
end
