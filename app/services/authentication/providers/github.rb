module Authentication
  module Providers
    # GitHub authentication provider, uses omniauth-github as backend
    class Github < Provider
      OFFICIAL_NAME = "GitHub".freeze
      CREATED_AT_FIELD = "github_created_at".freeze
      USERNAME_FIELD = "github_username".freeze
      SETTINGS_URL = "https://github.com/settings/applications".freeze

      def new_user_data
        name = raw_info.name.presence || info.name

        {
          email: info.email.to_s,
          github_created_at: raw_info.created_at,
          github_username: info.nickname,
          name: name,
          remote_profile_image_url: info.image.to_s
        }
      end

      def existing_user_data
        {
          github_created_at: raw_info.created_at,
          github_username: info.nickname
        }
      end

      def self.user_created_at_field
        CREATED_AT_FIELD
      end

      def self.user_username_field
        USERNAME_FIELD
      end

      def self.official_name
        OFFICIAL_NAME
      end

      def self.settings_url
        SETTINGS_URL
      end

      def self.sign_in_path(params = {})
        ::Authentication::Paths.sign_in_path(
          provider_name,
          params,
        )
      end

      protected

      def cleanup_payload(auth_payload)
        auth_payload
      end
    end
  end
end
