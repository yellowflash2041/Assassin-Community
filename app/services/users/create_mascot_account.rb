module Users
  class CreateMascotAccount
    MASCOT_PARAMS = {
      email: "mascot@forem.com",
      username: "mascot",
      name: "Mascot",
      profile_image: SiteConfig.mascot_image_url,
      confirmed_at: Time.current,
      registered_at: Time.current,
      password: SecureRandom.hex
    }.freeze

    def self.call
      new.call
    end

    def call
      raise "Mascot already set" if SiteConfig.mascot_user_id

      mascot = User.create!(mascot_params)
      SiteConfig.mascot_user_id = mascot.id
    end

    def mascot_params
      # Set the password_confirmation
      MASCOT_PARAMS.merge(password_confirmation: MASCOT_PARAMS[:password])
    end
  end
end
