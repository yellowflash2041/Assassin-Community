class Internal::BufferUpdatesController < Internal::ApplicationController
  skip_before_action :authorize_admin # Instead, specific admin via authorize([:internal, Article])
  before_action
  def create
    raise unless current_user.has_role?(:single_resource_admin, Article) || current_user.has_role?(:super_admin) || current_user.has_role?(:admin) 
    article_id = params[:article_id]
    article = Article.find(article_id) if article_id.present?
    fb_post = params[:fb_post]
    tweet = params[:tweet]
    listing_id = params[:listing_id]
    listing = ClassifiedListing.find(params[:listing_id]) if listing_id.present?
    case params[:social_channel]
    when "main_twitter"
      Bufferizer.new("article", article, tweet).main_tweet!
      render body: nil
    when "satellite_twitter"
      Bufferizer.new("article", article, tweet).satellite_tweet!
      render body: nil
    when "facebook"
      Bufferizer.new("article", article, fb_post).facebook_post!
      render body: nil
    when "listings_twitter"
      Bufferizer.new("listing", listing, tweet).listings_tweet!
      render body: nil
    end
  end

  def update
    raise unless current_user.has_role?(:single_resource_admin, Article) || current_user.has_role?(:super_admin) || current_user.has_role?(:admin) 
    BufferUpdate.upbuff!(params[:id], current_user.id, params[:body_text], params[:status])
    render body: nil
  end
end
