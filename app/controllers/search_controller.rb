class SearchController < ApplicationController
  before_action :authenticate_user!, only: %i[tags chat_channels reactions usernames]
  before_action :format_integer_params
  before_action :sanitize_params, only: %i[listings reactions feed_content]

  CHAT_CHANNEL_PARAMS = %i[
    channel_status
    channel_type
    page
    per_page
    status
    user_id
  ].freeze

  LISTINGS_PARAMS = [
    :category,
    :listing_search,
    :page,
    :per_page,
    :tag_boolean_mode,
    {
      tags: []
    },
  ].freeze

  REACTION_PARAMS = [
    :page,
    :per_page,
    :category,
    :search_fields,
    :tag_boolean_mode,
    {
      tag_names: [],
      status: []
    },
  ].freeze

  USER_PARAMS = %i[
    search_fields
    page
    per_page
  ].freeze

  FEED_PARAMS = [
    :approved,
    :class_name,
    :id,
    :organization_id,
    :page,
    :per_page,
    :search_fields,
    :sort_by,
    :sort_direction,
    :user_id,
    {
      tag_names: [],
      published_at: [:gte]
    },
  ].freeze

  def tags
    result = if FeatureFlag.enabled?(:search_2_tags)
               Search::Postgres::Tag.search_documents(params[:name])
             else
               Search::Tag.search_documents("name:#{params[:name]}* AND supported:true")
             end

    render json: { result: result }
  rescue Search::Errors::Transport::BadRequest
    render json: { result: [] }
  end

  def chat_channels
    user_ids =
      if chat_channel_params[:user_id].present?
        [current_user.id, SiteConfig.mascot_user_id, chat_channel_params[:user_id]].reject(&:blank?)
      else
        [current_user.id]
      end

    result = Search::Postgres::ChatChannelMembership.search_documents(
      user_ids: user_ids,
      page: chat_channel_params[:page],
      per_page: chat_channel_params[:per_page],
    )

    render json: { result: result }
  end

  def listings
    result =
      if FeatureFlag.enabled?(:search_2_listings)
        Search::Postgres::Listing.search_documents(
          category: listing_params[:category],
          page: listing_params[:page],
          per_page: listing_params[:per_page],
          term: listing_params[:listing_search],
        )
      else
        Search::Listing.search_documents(params: listing_params.to_h)
      end

    render json: { result: result }
  end

  def users
    render json: { result: user_search }
  end

  def usernames
    result = if FeatureFlag.enabled?(:search_2_usernames)
               Search::Postgres::Username.search_documents(params[:username])
             else
               Search::User.search_usernames(params[:username])
             end

    render json: { result: result }
  rescue Search::Errors::Transport::BadRequest
    render json: { result: [] }
  end

  def feed_content
    feed_docs = if params[:class_name].blank?
                  # If we are in the main feed and not filtering by type return
                  # all articles, podcast episodes, and users
                  feed_content_search.concat(user_search)
                elsif params[:class_name] == "User"
                  # No need to check for articles or podcast episodes if we know we only want users
                  user_search
                else
                  # if params[:class_name] == PodcastEpisode, Article, or Comment then skip user lookup
                  feed_content_search
                end

    render json: {
      result: feed_docs,
      display_jobs_banner: SiteConfig.display_jobs_banner,
      jobs_url: SiteConfig.jobs_url
    }
  end

  def reactions
    if FeatureFlag.enabled?(:search_2_reading_list)
      # [@rhymes] we're recyling the existing params as we want to change the frontend as
      # little as possible, we might simplify in the future
      result = Search::Postgres::ReadingList.search_documents(
        current_user,
        page: reaction_params[:page],
        per_page: reaction_params[:per_page],
        statuses: reaction_params[:status],
        tags: reaction_params[:tag_names],
        term: reaction_params[:search_fields],
      )

      render json: { result: result[:items], total: result[:total] }
    else
      result = Search::ReadingList.search_documents(
        params: reaction_params.to_h, user: current_user,
      )

      render json: { result: result["reactions"], total: result["total"] }
    end
  end

  private

  def feed_content_search
    Search::FeedContent.search_documents(params: feed_params.to_h)
  end

  def user_search
    Search::User.search_documents(params: user_params.to_h)
  end

  def chat_channel_params
    params.permit(CHAT_CHANNEL_PARAMS)
  end

  def listing_params
    params.permit(LISTINGS_PARAMS)
  end

  def user_params
    params.permit(USER_PARAMS)
  end

  def feed_params
    params.permit(FEED_PARAMS)
  end

  def reaction_params
    params.permit(REACTION_PARAMS)
  end

  def format_integer_params
    params[:page] = params[:page].to_i if params[:page].present?
    params[:per_page] = params[:per_page].to_i if params[:per_page].present?
  end

  # Some Elasticsearches/QueryBuilders treat values such as empty Strings and
  # nil differently. This is a helper method to remove any params that are
  # blank before passing it to Elasticsearch.
  def sanitize_params
    params.delete_if { |_k, v| v.blank? }
  end
end
