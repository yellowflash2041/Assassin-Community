class Internal::ConfigsController < Internal::ApplicationController
  layout "internal"

  def show
    @logo_svg = SiteConfig.logo_svg.html_safe # rubocop:disable Rails/OutputSafety
  end

  def create
    clean_up_params
    config_params.keys.each do |key|
      SiteConfig.public_send("#{key}=", config_params[key].strip) unless config_params[key].nil?
    end
    bust_relevant_caches
    redirect_to internal_config_path, notice: "Site configuration was successfully updated."
  end

  private

  def config_params
    allowed_params = %i[
      staff_user_id default_site_email social_networks_handle
      main_social_image favicon_url logo_svg
      rate_limit_follow_count_daily
      ga_view_id ga_fetch_rate
      mailchimp_newsletter_id mailchimp_sustaining_members_id
      mailchimp_tag_moderators_id mailchimp_community_moderators_id
      periodic_email_digest_max periodic_email_digest_min suggested_tags
    ]
    params.require(:site_config).permit(allowed_params)
  end

  def clean_up_params
    config = params[:site_config]
    config[:suggested_tags] = config[:suggested_tags].downcase.delete(" ") if config[:suggested_tags]
  end

  def bust_relevant_caches
    CacheBuster.bust("/api/tags/onboarding") # Needs to change when suggested_tags is edited
  end
end
