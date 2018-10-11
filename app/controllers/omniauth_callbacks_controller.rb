class OmniauthCallbacksController < Devise::OmniauthCallbacksController
  # Don't need a policy for this since this is our sign up/in route
  include Devise::Controllers::Rememberable
  def self.provides_callback_for(provider)
    # raise ApplicationConfig["omniauth.auth"].to_yaml
    class_eval %{
      def #{provider}
        cta_variant = request.env["omniauth.params"]['state'].to_s
        @user = AuthorizationService.new(request.env["omniauth.auth"], current_user, cta_variant).get_user
        if @user.persisted? && @user.valid?
          remember_me(@user)
          sign_in_and_redirect @user, event: :authentication
          set_flash_message(:notice, :success, kind: "#{provider}".capitalize) if is_navigational_format?
        elsif @user.persisted? && @user.errors.full_messages.join(", ").include?("username has already been taken")
          redirect_to "/settings?state=previous-registration"
        else
          session["devise.#{provider}_data"] = request.env["omniauth.auth"]
          user_errors = @user.errors.full_messages
          flash[:alert] = user_errors
          redirect_to new_user_registration_url
        end
      end
    }
  end

  %i[twitter github].each do |provider|
    provides_callback_for provider
  end
end
