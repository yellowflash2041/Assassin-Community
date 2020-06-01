module Api
  module V0
    class HealthChecksController < ApiController
      before_action :authenticate_with_token

      def app
        render json: { message: "App is up!" }, status: :ok
      end

      def search
        if Search::Client.ping
          render json: { message: "Search ping succeeded!" }, status: :ok
        else
          render json: { message: "Search ping failed!" }, status: :internal_server_error
        end
      end

      def database
        if ActiveRecord::Base.connected?
          render json: { message: "Database connected" }, status: :ok
        else
          render json: { message: "Database NOT connected!" }, status: :internal_server_error
        end
      end

      def cache
        if all_cache_instances_connected?
          render json: { message: "Redis connected" }, status: :ok
        else
          render json: { message: "Redis NOT connected!" }, status: :internal_server_error
        end
      end

      private

      def authenticate_with_token
        key = request.headers["health-check-token"]

        return if key == SiteConfig.health_check_token

        error_unauthorized
      end

      def all_cache_instances_connected?
        [ENV["REDIS_URL"], ENV["REDIS_SESSIONS_URL"], ENV["REDIS_SIDEKIQ_URL"]].compact.all? do |url|
          Redis.new(url: url).ping == "PONG"
        end
      end
    end
  end
end
