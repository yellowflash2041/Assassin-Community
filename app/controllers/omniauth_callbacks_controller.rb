class OmniauthCallbacksController < Devise::OmniauthCallbacksController
  # Don't need a policy for this since this is our sign up/in route
  include Devise::Controllers::Rememberable

  def twitter
    callback_for("twitter")
  end

  def github
    callback_for("github")
  end

  private

  def callback_for(provider)
    cta_variant = request.env["omniauth.params"]["state"].to_s
    @user = AuthorizationService.new(request.env["omniauth.auth"], current_user, cta_variant).get_user
    if persisted_and_valid?
      remember_me(@user)
      sign_in_and_redirect @user, event: :authentication
      set_flash_message(:notice, :success, kind: provider.to_s.capitalize) if is_navigational_format?
    elsif persisted_but_username_taken?
      redirect_to "/settings?state=previous-registration"
    else
      session["devise.#{provider}_data"] = request.env["omniauth.auth"]
      user_errors = @user.errors.full_messages
      flash[:alert] = user_errors
      redirect_to new_user_registration_url
    end
  end

  def persisted_and_valid?
    @user.persisted? && @user.valid?
  end

  def persisted_but_username_taken?
    @user.persisted? && @user.errors.full_messages.join(", ").include?("username has already been taken")
  end
end
