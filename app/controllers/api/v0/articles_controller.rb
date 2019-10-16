module Api
  module V0
    class ArticlesController < ApiController
      respond_to :json

      before_action :authenticate_with_api_key_or_current_user!, only: %i[create update]
      before_action :authenticate!, only: :me
      before_action -> { doorkeeper_authorize! :public }, only: %w[index show], if: -> { doorkeeper_token }

      before_action :set_cache_control_headers, only: [:index]
      caches_action :show,
                    cache_path: proc { |c| c.params.permit! },
                    expires_in: 5.minutes

      before_action :cors_preflight_check
      after_action :cors_set_access_control_headers

      # skip CSRF checks for create and update
      skip_before_action :verify_authenticity_token, only: %i[create update]

      def index
        @articles = ArticleApiIndexService.new(params).get

        key_headers = [
          "articles_api",
          params[:tag],
          params[:page],
          params[:username],
          params[:signature],
          params[:state],
          params[:collection_id],
        ]
        set_surrogate_key_header key_headers.join("_")
      end

      def show
        @article = Article.published.includes(:user).find(params[:id]).decorate
      end

      def create
        @article = Articles::Creator.call(@user, article_params)
        if @article.persisted?
          render "show", status: :created, location: @article.url
        else
          message = @article.errors.full_messages.join(", ")
          render json: { error: message, status: 422 }, status: :unprocessable_entity
        end
      end

      def update
        @article = Articles::Updater.call(@user, params[:id], article_params)
        render "show", status: :ok
      end

      def me
        doorkeeper_scope = %w[unpublished all].include?(params[:status]) ? :read_articles : :public
        doorkeeper_authorize! doorkeeper_scope if doorkeeper_token

        per_page = (params[:per_page] || 30).to_i
        num = [per_page, 1000].min

        @articles = case params[:status]
                    when "published"
                      @user.articles.published
                    when "unpublished"
                      @user.articles.unpublished
                    when "all"
                      @user.articles
                    else
                      @user.articles.published
                    end

        @articles = @articles.
          includes(:organization).
          order(published_at: :desc, created_at: :desc).
          page(params[:page]).
          per(num).
          decorate
      end

      private

      def article_params
        allowed_params = [
          :title, :body_markdown, :published, :series,
          :main_image, :canonical_url, :description, tags: []
        ]
        allowed_params << :organization_id if params["article"]["organization_id"] && allowed_to_change_org_id?
        params.require(:article).permit(allowed_params)
      end

      def allowed_to_change_org_id?
        potential_user = @article&.user || @user
        if @article.nil? || OrganizationMembership.exists?(user: potential_user, organization_id: params["article"]["organization_id"])
          OrganizationMembership.exists?(user: potential_user, organization_id: params["article"]["organization_id"])
        elsif potential_user == @user
          potential_user.org_admin?(params["article"]["organization_id"]) ||
            @user.any_admin?
        end
      end
    end
  end
end
