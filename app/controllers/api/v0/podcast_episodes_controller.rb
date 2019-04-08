module Api
  module V0
    class PodcastEpisodesController < ApiController
      caches_action :index,
                    cache_path: proc { |c| c.params.permit! },
                    expires_in: 10.minutes
      respond_to :json

      before_action :cors_preflight_check
      after_action :cors_set_access_control_headers

      def index
        @page = params[:page]

        if params[:username]
          @podcast = Podcast.find_by(slug: params[:username]) || not_found
          @podcast_episodes = @podcast.
            podcast_episodes.order("published_at desc").
            page(@page).
            per(30)
        else
          @podcast_episodes = PodcastEpisode.order("published_at desc").page(@page).per(30)
        end
      end
    end
  end
end
