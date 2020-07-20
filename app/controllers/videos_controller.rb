class VideosController < ApplicationController
  after_action :verify_authorized, except: %i[index]
  before_action :set_cache_control_headers, only: %i[index]
  before_action :authorize_video, only: %i[new create]

  def new; end

  def index
    @video_articles = Article.with_video
      .includes([:user])
      .select(:id, :video, :path, :title, :video_thumbnail_url, :user_id, :video_duration_in_seconds)
      .order(hotness_score: :desc)
      .page(params[:page].to_i).per(24)

    set_surrogate_key_header "videos", Article.table_key, @video_articles.map(&:record_key)
  end

  def create
    @article = ArticleWithVideoCreationService.new(article_params, current_user).create!

    redirect_to @article.path + "/edit"
  end

  private

  def authorize_video
    authorize :video
  end

  def article_params
    params.require(:article).permit(:video)
  end
end
