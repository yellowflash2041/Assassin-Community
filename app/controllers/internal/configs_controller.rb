class Internal::ConfigsController < Internal::ApplicationController
  layout "internal"

  before_action :extra_authorization_and_confirmation, only: [:create]

  def show
    @logo_svg = SiteConfig.logo_svg.html_safe # rubocop:disable Rails/OutputSafety
  end

  def create
    clean_up_params

    config_params.each do |key, value|
      if value.is_a?(Array)
        SiteConfig.public_send("#{key}=", value.reject(&:blank?)) unless value.empty?
      elsif value.respond_to?(:to_h)
        SiteConfig.public_send("#{key}=", value.to_h) unless value.empty?
      else
        SiteConfig.public_send("#{key}=", value.strip) unless value.nil?
      end
    end

    bust_relevant_caches
    redirect_to internal_config_path, notice: "Site configuration was successfully updated."
  end

  private

  def config_params
    allowed_params = %i[
      ga_view_id ga_fetch_rate
      periodic_email_digest_max
      periodic_email_digest_min
      sidebar_tags
      twitter_hashtag
      shop_url
      payment_pointer
      health_check_token
    ]

    allowed_params = allowed_params |
      campaign_params |
      community_params |
      newsletter_params |
      rate_limit_params |
      mascot_params |
      image_params |
      onboarding_params |
      job_params

    params.require(:site_config).permit(
      allowed_params,
      authentication_providers: [],
      social_media_handles: SiteConfig.social_media_handles.keys,
      email_addresses: SiteConfig.email_addresses.except(:default).keys,
      meta_keywords: SiteConfig.meta_keywords.keys,
    )
  end

  def extra_authorization_and_confirmation
    not_authorized unless current_user.has_role?(:single_resource_admin, Config) # Special additional permission
    not_authorized if params[:confirmation] != "My username is @#{current_user.username} and this action is 100% safe and appropriate."
  end

  def clean_up_params
    config = params[:site_config]
    %i[sidebar_tags suggested_tags suggested_users].each do |param|
      config[param] = config[param].downcase.delete(" ") if config[param]
    end
  end

  def bust_relevant_caches
    # Needs to change when suggested_tags is edited.
    CacheBuster.bust("/tags/onboarding")
  end

  def campaign_params
    %i[
      campaign_featured_tags
      campaign_hero_html_variant_name
      campaign_sidebar_enabled
      campaign_sidebar_image
      campaign_url
      campaign_articles_require_approval
    ]
  end

  def community_params
    %i[
      community_description
      community_member_description
      community_member_label
      community_action
      tagline
    ]
  end

  def newsletter_params
    %i[
      mailchimp_community_moderators_id
      mailchimp_newsletter_id
      mailchimp_sustaining_members_id
      mailchimp_tag_moderators_id
    ]
  end

  def rate_limit_params
    %i[
      rate_limit_comment_creation
      rate_limit_email_recipient
      rate_limit_follow_count_daily
      rate_limit_image_upload
      rate_limit_published_article_creation
      rate_limit_organization_creation
    ]
  end

  def mascot_params
    %i[
      mascot_image_description
      mascot_image_url
      mascot_user_id
    ]
  end

  def image_params
    %i[
      favicon_url
      logo_png
      logo_svg
      main_social_image
      primary_sticker_image_url
    ]
  end

  def onboarding_params
    %i[
      onboarding_taskcard_image
      suggested_tags
      suggested_users
    ]
  end

  def job_params
    %i[
      jobs_url
      display_jobs_banner
    ]
  end
end
