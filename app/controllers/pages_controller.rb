class PagesController < ApplicationController
  # No authorization required for entirely public controller
  before_action :set_cache_control_headers, only: %i[rlyweb now membership survey badge shecoded]

  def now
    set_surrogate_key_header "now_page"
  end

  def survey
    set_surrogate_key_header "survey_page"
  end

  def about
    set_surrogate_key_header "about_page"
  end

  def badge
    @html_variant = HtmlVariant.find_for_test([], "badge_landing_page")
    render layout: false
    set_surrogate_key_header "badge_page"
  end

  def membership
    flash[:notice] = ""
    flash[:error] = ""
    @members = members_for_display
    set_surrogate_key_header "membership_page"
  end

  def membership_form
    render "membership_form", layout: false
  end

  def report_abuse
    reported_url = params[:reported_url] || params[:url] || request.referer
    @feedback_message = FeedbackMessage.new(
      reported_url: reported_url&.chomp("?i=i"),
    )
    render "pages/report-abuse"
  end

  def rlyweb
    set_surrogate_key_header "rlyweb"
  end

  def welcome
    daily_thread = latest_published_welcome_thread
    if daily_thread
      redirect_to daily_thread.path
    else
      # fail safe if we haven't made the first welcome thread
      redirect_to "/notifications"
    end
  end

  def live
    @active_channel = ChatChannel.find_by(channel_name: "Workshop")
    @chat_channels = [@active_channel].to_json(
      only: %i[channel_name channel_type last_message_at slug status id],
    )
  end

  def shecoded
    @top_articles = Article.published.tagged_with(%w[shecoded shecodedally theycoded], any: true).
      where(approved: true).where("published_at > ? AND score > ?", 3.weeks.ago, 28).
      order(Arel.sql("RANDOM()")).
      includes(:user).decorate
    @articles = Article.published.tagged_with(%w[shecoded shecodedally theycoded], any: true).
      where(approved: true).where("published_at > ? AND score > ?", 3.weeks.ago, -8).
      order(Arel.sql("RANDOM()")).
      where.not(id: @top_articles.pluck(:id)).
      includes(:user).decorate
    render layout: false
    set_surrogate_key_header "shecoded_page"
  end

  private # helpers

  def latest_published_welcome_thread
    Article.published.where(user_id: ApplicationConfig["DEVTO_USER_ID"]).tagged_with("welcome").last
  end

  def members_for_display
    Rails.cache.fetch("members-for-display-on-membership-page", expires_in: 6.hours) do
      roles = %i[level_1_member level_2_member level_3_member level_4_member triple_unicorn_member
                 workshop_pass]
      members = User.select(:id, :username, :profile_image).with_any_role(*roles)
      team_ids = [1, 264, 6, 3, 31_047, 510, 560, 1075, 48_943, 13_962]
      members.reject { |user| team_ids.include?(user.id) }.shuffle
    end
  end
end
