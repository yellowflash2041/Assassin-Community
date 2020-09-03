class OmniauthCallbacksController < Devise::OmniauthCallbacksController
  include Devise::Controllers::Rememberable

  # Each available authentication method needs a related action that will be called
  # as a callback on successful redirect from the upstream OAuth provider
  Authentication::Providers.available.each do |provider_name|
    define_method(provider_name) do
      callback_for(provider_name)
    end
  end

  # Callback for third party failures (shared by all providers)
  def failure
    error = request.env["omniauth.error"]
    class_name = error.present? ? error.class.name : ""

    DatadogStatsClient.increment(
      "omniauth.failure",
      tags: [
        "class:#{class_name}",
        "message:#{error&.message}",
        "reason:#{error.try(:error_reason)}",
        "type:#{error.try(:error)}",
        "uri:#{error.try(:error_uri)}",
        "provider:#{request.env['omniauth.strategy'].name}",
        "origin:#{request.env['omniauth.strategy.origin']}",
        "params:#{request.env['omniauth.params']}",
      ],
    )

    super
  end

  private

  def callback_for(provider)
    # Deleting the session cookie with the legacy app domain, which does NOT include a preceding dot.
    # This should fix the double cookie scenario.
    # TODO: this code is a hotfix, we should remove it after 09/18/2020.
    legacy_cookie_domain = Rails.env.production? ? ApplicationConfig["APP_DOMAIN"] : nil
    cookies.delete(ApplicationConfig["SESSION_KEY"], domain: legacy_cookie_domain)

    auth_payload = request.env["omniauth.auth"]
    cta_variant = request.env["omniauth.params"]["state"].to_s

    @user = Authentication::Authenticator.call(
      auth_payload,
      current_user: current_user,
      cta_variant: cta_variant,
    )

    if user_persisted_and_valid?
      # Devise's Omniauthable does not automatically remember users
      # see <https://github.com/heartcombo/devise/wiki/Omniauthable,-sign-out-action-and-rememberable>
      remember_me(@user)

      set_flash_message(:notice, :success, kind: provider.to_s.titleize) if is_navigational_format?

      # `event: authentication` is only needed for Warden callbacks
      # see <config/initializers/persistent_csrf_token_cookie.rb>
      sign_in_and_redirect(@user, event: :authentication)
    # NOTE: I can't find a way to test this path
    # as `User` will assign a temporary username if the username already exists
    # see https://github.com/thepracticaldev/dev.to/blob/27131f6f420df347a467f8e9afc84a6af2fcb13a/app/models/user.rb#L532-L555
    elsif user_persisted_but_username_taken?
      redirect_to "/settings?state=previous-registration"
    # NOTE: I can't find a way to test this path
    # as `Authentication::Authenticator.call` invokes `User.save!` which will
    # raise errors for a validation error.
    # In the past we had 1 path (update_user) which would have ended up
    # here in case of validation errors, see:
    # https://github.com/thepracticaldev/dev.to/blob/80737b540453afe8775128cb37bd379b7c09c7e8/app/services/authorization_service.rb#L77
    else
      # Devise will clean this data when the user is not persisted
      session["devise.#{provider}_data"] = request.env["omniauth.auth"]

      user_errors = @user.errors.full_messages

      Honeybadger.context({
                            username: @user.username,
                            user_id: @user.id,
                            auth_data: request.env["omniauth.auth"],
                            auth_error: request.env["omniauth.error"]&.inspect,
                            user_errors: user_errors
                          })
      Honeybadger.notify("Omniauth log in error")

      flash[:alert] = user_errors
      redirect_to new_user_registration_url
    end
  rescue StandardError => e
    Honeybadger.notify(e)

    flash[:alert] = "Log in error: #{e}"
    redirect_to new_user_registration_url
  end

  def user_persisted_and_valid?
    @user.persisted? && @user.valid?
  end

  def user_persisted_but_username_taken?
    @user.persisted? && @user.errors_as_sentence.include?("username has already been taken")
  end
end
