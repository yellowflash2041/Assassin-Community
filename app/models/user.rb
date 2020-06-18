class User < ApplicationRecord
  resourcify

  include CloudinaryHelper
  include Searchable
  include Storext.model

  BEHANCE_URL_REGEXP = /\A(http(s)?:\/\/)?(www.behance.net|behance.net)\/.*\z/.freeze
  COLOR_HEX_REGEXP = /\A#([A-Fa-f0-9]{6}|[A-Fa-f0-9]{3})\z/.freeze
  DRIBBBLE_URL_REGEXP = /\A(http(s)?:\/\/)?(www.dribbble.com|dribbble.com)\/.*\z/.freeze
  EDITORS = %w[v1 v2].freeze
  FACEBOOK_URL_REGEXP = /\A(http(s)?:\/\/)?(www.facebook.com|facebook.com)\/.*\z/.freeze
  FONTS = %w[default sans_serif monospace comic_sans open_dyslexic].freeze
  GITLAB_URL_REGEXP = /\A(http(s)?:\/\/)?(www.gitlab.com|gitlab.com)\/.*\z/.freeze
  INBOXES = %w[open private].freeze
  INSTAGRAM_URL_REGEXP = /\A(http(s)?:\/\/)?(?:www.)?instagram.com\/(?=.{1,30}\/?$)([a-zA-Z\d_]\.?)*[a-zA-Z\d_]+\/?\z/.freeze
  LINKEDIN_URL_REGEXP = /\A(http(s)?:\/\/)?(www.linkedin.com|linkedin.com|[A-Za-z]{2}.linkedin.com)\/.*\z/.freeze
  MEDIUM_URL_REGEXP = /\A(http(s)?:\/\/)?(www.medium.com|medium.com)\/.*\z/.freeze
  NAVBARS = %w[default static].freeze
  STACKOVERFLOW_URL_REGEXP = /\A(http(s)?:\/\/)?(((www|pt|ru|es|ja).)?stackoverflow.com|(www.)?stackexchange.com)\/.*\z/.freeze
  YOUTUBE_URL_REGEXP = /\A(http(s)?:\/\/)?(www.youtube.com|youtube.com)\/.*\z/.freeze
  STREAMING_PLATFORMS = %w[twitch].freeze
  THEMES = %w[default night_theme pink_theme minimal_light_theme ten_x_hacker_theme].freeze
  TWITCH_URL_REGEXP = /\A(http(s)?:\/\/)?(www.twitch.tv|twitch.tv)\/.*\z/.freeze
  USERNAME_MAX_LENGTH = 30
  USERNAME_REGEXP = /\A[a-zA-Z0-9_]+\z/.freeze
  MESSAGES = {
    invalid_config_font: "%<value>s is not a valid font selection",
    invalid_config_navbar: "%<value>s is not a valid navbar value",
    invalid_config_theme: "%<value>s is not a valid theme",
    invalid_editor_version: "%<value>s must be either v1 or v2",
    reserved_username: "username is reserved"
  }.freeze

  attr_accessor :scholar_email, :new_note, :note_for_current_role, :user_status, :pro, :merge_user_id,
                :add_credits, :remove_credits, :add_org_credits, :remove_org_credits, :ghostify,
                :ip_address

  rolify after_add: :index_roles, after_remove: :index_roles

  SEARCH_SERIALIZER = Search::UserSerializer
  SEARCH_CLASS = Search::User
  DATA_SYNC_CLASS = DataSync::Elasticsearch::User

  acts_as_followable
  acts_as_follower

  has_many :source_authored_user_subscriptions, class_name: "UserSubscription", foreign_key: :author_id, inverse_of: :author, dependent: :destroy
  has_many :subscribers, through: :source_authored_user_subscriptions, dependent: :destroy
  has_many :subscribed_to_user_subscriptions, class_name: "UserSubscription", foreign_key: :subscriber_id, inverse_of: :subscriber, dependent: :destroy

  has_many :access_grants, class_name: "Doorkeeper::AccessGrant", foreign_key: :resource_owner_id, inverse_of: :resource_owner, dependent: :delete_all
  has_many :access_tokens, class_name: "Doorkeeper::AccessToken", foreign_key: :resource_owner_id, inverse_of: :resource_owner, dependent: :delete_all
  has_many :affected_feedback_messages, class_name: "FeedbackMessage", inverse_of: :affected, foreign_key: :affected_id, dependent: :nullify
  has_many :api_secrets, dependent: :destroy
  has_many :articles, dependent: :destroy
  has_many :audit_logs, dependent: :nullify
  has_many :authored_notes, inverse_of: :author, class_name: "Note", foreign_key: :author_id, dependent: :delete_all
  has_many :backup_data, foreign_key: "instance_user_id", inverse_of: :instance_user, class_name: "BackupData", dependent: :delete_all
  has_many :badge_achievements, dependent: :destroy
  has_many :badges, through: :badge_achievements
  has_many :blocked_blocks, class_name: "UserBlock", foreign_key: :blocked_id, inverse_of: :blocked, dependent: :delete_all
  has_many :blocker_blocks, class_name: "UserBlock", foreign_key: :blocker_id, inverse_of: :blocker, dependent: :delete_all
  has_many :chat_channel_memberships, dependent: :destroy
  has_many :chat_channels, through: :chat_channel_memberships
  has_many :listings, dependent: :destroy
  has_many :collections, dependent: :destroy
  has_many :comments, dependent: :destroy
  has_many :created_podcasts, class_name: "Podcast", foreign_key: :creator_id, inverse_of: :creator, dependent: :nullify
  has_many :credits, dependent: :destroy
  has_many :display_ad_events, dependent: :destroy
  has_many :email_authorizations, dependent: :delete_all
  has_many :email_messages, class_name: "Ahoy::Message", dependent: :destroy
  has_many :field_test_memberships, class_name: "FieldTest::Membership", as: :participant, dependent: :destroy
  has_many :github_repos, dependent: :destroy
  has_many :html_variants, dependent: :destroy
  has_many :identities, dependent: :destroy
  has_many :identities_enabled, -> { enabled }, class_name: "Identity", inverse_of: false
  has_many :mentions, dependent: :destroy
  has_many :messages, dependent: :destroy
  has_many :notes, as: :noteable, inverse_of: :noteable
  has_many :notification_subscriptions, dependent: :destroy
  has_many :user_optional_fields, dependent: :destroy
  has_many :notifications, dependent: :destroy
  has_many :offender_feedback_messages, class_name: "FeedbackMessage", inverse_of: :offender, foreign_key: :offender_id, dependent: :nullify
  has_many :organization_memberships, dependent: :destroy
  has_many :organizations, through: :organization_memberships
  has_many :page_views, dependent: :destroy
  has_many :poll_skips, dependent: :destroy
  has_many :poll_votes, dependent: :destroy
  has_many :profile_pins, as: :profile, inverse_of: :profile, dependent: :delete_all
  has_many :rating_votes, dependent: :destroy
  has_many :reactions, dependent: :destroy
  has_many :reporter_feedback_messages, class_name: "FeedbackMessage", inverse_of: :reporter, foreign_key: :reporter_id, dependent: :nullify
  has_many :response_templates, inverse_of: :user, dependent: :destroy
  has_many :tweets, dependent: :destroy
  has_many :webhook_endpoints, class_name: "Webhook::Endpoint", inverse_of: :user, dependent: :delete_all

  mount_uploader :profile_image, ProfileImageUploader

  devise :omniauthable, :registerable, :database_authenticatable, :confirmable, :rememberable

  validates :behance_url, length: { maximum: 100 }, allow_blank: true, format: BEHANCE_URL_REGEXP
  validates :bg_color_hex, format: COLOR_HEX_REGEXP, allow_blank: true
  validates :config_font, inclusion: { in: FONTS, message: MESSAGES[:invalid_config_font] }
  validates :config_navbar, inclusion: { in: NAVBARS, message: MESSAGES[:invalid_config_navbar] }
  validates :config_theme, inclusion: { in: THEMES, message: MESSAGES[:invalid_config_theme] }
  validates :currently_streaming_on, inclusion: { in: STREAMING_PLATFORMS }, allow_nil: true
  validates :dribbble_url, length: { maximum: 100 }, allow_blank: true, format: DRIBBBLE_URL_REGEXP
  validates :editor_version, inclusion: { in: EDITORS, message: MESSAGES[:invalid_editor_version] }
  validates :email, length: { maximum: 50 }, email: true, allow_nil: true
  validates :email, uniqueness: { allow_nil: true, case_sensitive: false }, if: :email_changed?
  validates :employer_name, :employer_url, length: { maximum: 100 }
  validates :employment_title, :education, :location, length: { maximum: 100 }
  validates :experience_level, numericality: { less_than_or_equal_to: 10 }, allow_blank: true
  validates :facebook_url, length: { maximum: 1000 }, format: FACEBOOK_URL_REGEXP, allow_blank: true
  validates :feed_referential_link, inclusion: { in: [true, false] }
  validates :feed_url, length: { maximum: 500 }, allow_nil: true
  validates :github_username, uniqueness: { allow_nil: true }, if: :github_username_changed?
  validates :gitlab_url, length: { maximum: 100 }, allow_blank: true, format: GITLAB_URL_REGEXP
  validates :inbox_guidelines, length: { maximum: 250 }, allow_nil: true
  validates :inbox_type, inclusion: { in: INBOXES }
  validates :instagram_url, length: { maximum: 100 }, allow_blank: true, format: INSTAGRAM_URL_REGEXP
  validates :linkedin_url, length: { maximum: 350 }, allow_blank: true, format: LINKEDIN_URL_REGEXP
  validates :mastodon_url, length: { maximum: 100 }
  validates :medium_url, length: { maximum: 200 }, allow_blank: true, format: MEDIUM_URL_REGEXP
  validates :mostly_work_with, :currently_learning, :currently_hacking_on, :available_for, length: { maximum: 500 }
  validates :name, length: { in: 1..100 }
  validates :stackoverflow_url, length: { maximum: 150 }, allow_blank: true, format: STACKOVERFLOW_URL_REGEXP
  validates :summary, length: { maximum: 1300 }, allow_nil: true
  validates :text_color_hex, format: COLOR_HEX_REGEXP, allow_blank: true
  validates :twitch_url, length: { maximum: 100 }, allow_blank: true, format: TWITCH_URL_REGEXP
  validates :twitter_username, uniqueness: { allow_nil: true }, if: :twitter_username_changed?
  validates :username, presence: true, exclusion: { in: ReservedWords.all, message: MESSAGES[:invalid_username] }
  validates :username, length: { in: 2..USERNAME_MAX_LENGTH }, format: USERNAME_REGEXP
  validates :username, uniqueness: { case_sensitive: false }, if: :username_changed?
  validates :website_url, :employer_url, url: { allow_blank: true, no_local: true }
  validates :website_url, length: { maximum: 100 }, allow_nil: true
  validates :youtube_url, length: { maximum: 1000 }, format: YOUTUBE_URL_REGEXP, allow_blank: true

  validate :conditionally_validate_summary
  validate :non_banished_username, :username_changed?
  validate :unique_including_orgs_and_podcasts, if: :username_changed?
  validate :validate_feed_url, if: :feed_url_changed?
  validate :validate_mastodon_url
  validate :can_send_confirmation_email
  validate :update_rate_limit

  alias_attribute :public_reactions_count, :reactions_count
  alias_attribute :subscribed_to_welcome_notifications?, :welcome_notifications

  scope :eager_load_serialized_data, -> { includes(:roles) }

  after_save :bust_cache
  after_save :subscribe_to_mailchimp_newsletter
  after_save :conditionally_resave_articles

  before_create :set_default_language
  before_validation :set_username
  # make sure usernames are not empty, to be able to use the database unique index
  before_validation :verify_twitter_username, :verify_github_username, :verify_email, :verify_twitch_username
  before_validation :set_config_input
  before_validation :downcase_email
  before_validation :check_for_username_change
  before_destroy :destroy_follows, prepend: true
  before_destroy :unsubscribe_from_newsletters, prepend: true

  after_create_commit :send_welcome_notification, :estimate_default_language
  after_commit :index_to_elasticsearch, on: %i[create update]
  after_commit :sync_related_elasticsearch_docs, on: %i[create update]
  after_commit :remove_from_elasticsearch, on: [:destroy]

  def self.dev_account
    find_by(id: SiteConfig.staff_user_id)
  end

  def self.mascot_account
    find_by(id: SiteConfig.mascot_user_id)
  end

  def estimated_default_language
    language_settings["estimated_default_language"]
  end

  def tag_line
    summary
  end

  def set_remember_fields
    self.remember_token ||= self.class.remember_token if respond_to?(:remember_token)
    self.remember_created_at ||= Time.now.utc
  end

  def calculate_score
    score = (articles.where(featured: true).size * 100) + comments.sum(:score)
    update_column(:score, score)
  end

  def path
    "/" + username.to_s
  end

  def followed_articles
    Article.tagged_with(cached_followed_tag_names, any: true).
      union(Article.where(user_id: cached_following_users_ids)).
      where(language: preferred_languages_array, published: true)
  end

  def cached_following_users_ids
    cache_key = "user-#{id}-#{last_followed_at}-#{following_users_count}/following_users_ids"
    Rails.cache.fetch(cache_key, expires_in: 12.hours) do
      Follow.follower_user(id).limit(150).pluck(:followable_id)
    end
  end

  def cached_following_organizations_ids
    cache_key = "user-#{id}-#{last_followed_at}-#{following_orgs_count}/following_organizations_ids"
    Rails.cache.fetch(cache_key, expires_in: 12.hours) do
      Follow.follower_organization(id).limit(150).pluck(:followable_id)
    end
  end

  def cached_following_podcasts_ids
    cache_key = "user-#{id}-#{last_followed_at}/following_podcasts_ids"
    Rails.cache.fetch(cache_key, expires_in: 12.hours) do
      Follow.follower_podcast(id).pluck(:followable_id)
    end
  end

  # handles both old (prefer_language_*) and new (Array of language codes) formats
  def preferred_languages_array
    return @preferred_languages_array if defined?(@preferred_languages_array)

    if language_settings["preferred_languages"].present?
      @preferred_languages_array = language_settings["preferred_languages"].to_a
    else
      languages = []
      language_settings.each_key do |setting|
        languages << setting.split("prefer_language_")[1] if language_settings[setting] && setting.include?("prefer_language_")
      end
      @preferred_languages_array = languages
    end
    @preferred_languages_array
  end

  def processed_website_url
    website_url.to_s.strip if website_url.present?
  end

  def remember_me
    true
  end

  def cached_followed_tag_names
    cache_name = "user-#{id}-#{following_tags_count}-#{last_followed_at&.rfc3339}/followed_tag_names"
    Rails.cache.fetch(cache_name, expires_in: 24.hours) do
      Tag.where(
        id: Follow.where(
          follower_id: id,
          followable_type: "ActsAsTaggableOn::Tag",
        ).pluck(:followable_id),
      ).pluck(:name)
    end
  end

  # methods for Administrate field
  def banned
    has_role? :banned
  end

  def warned
    has_role? :warned
  end

  def admin?
    has_role?(:super_admin)
  end

  def any_admin?
    has_role?(:super_admin) || has_role?(:admin)
  end

  def tech_admin?
    has_role?(:tech_admin) || has_role?(:super_admin)
  end

  def pro?
    Rails.cache.fetch("user-#{id}/has_pro_role", expires_in: 200.hours) do
      has_role?(:pro)
    end
  end

  def vomitted_on?
    Reaction.exists?(reactable_id: id, reactable_type: "User", category: "vomit", status: "confirmed")
  end

  def trusted
    @trusted ||= Rails.cache.fetch("user-#{id}/has_trusted_role", expires_in: 200.hours) do
      has_role? :trusted
    end
  end

  def moderator_for_tags
    Rails.cache.fetch("user-#{id}/tag_moderators_list", expires_in: 200.hours) do
      tag_ids = roles.where(name: "tag_moderator").pluck(:resource_id)
      Tag.where(id: tag_ids).pluck(:name)
    end
  end

  def comment_banned
    has_role? :comment_banned
  end

  def workshop_eligible?
    has_any_role?(:workshop_pass)
  end

  def admin_organizations
    org_ids = organization_memberships.where(type_of_user: "admin").pluck(:organization_id)
    organizations.where(id: org_ids)
  end

  def member_organizations
    org_ids = organization_memberships.where(type_of_user: %w[admin member]).pluck(:organization_id)
    organizations.where(id: org_ids)
  end

  def org_member?(organization)
    OrganizationMembership.exists?(user: self, organization: organization, type_of_user: %w[admin member])
  end

  def org_admin?(organization)
    OrganizationMembership.exists?(user: self, organization: organization, type_of_user: "admin")
  end

  def block; end

  def all_blocking
    UserBlock.where(blocker_id: id)
  end

  def all_blocked_by
    UserBlock.where(blocked_id: id)
  end

  def blocking?(blocked_id)
    UserBlock.blocking?(id, blocked_id)
  end

  def blocked_by?(blocker_id)
    UserBlock.blocking?(blocker_id, id)
  end

  def unique_including_orgs_and_podcasts
    username_taken = (
      Organization.exists?(slug: username) ||
      Podcast.exists?(slug: username) ||
      Page.exists?(slug: username)
    )

    errors.add(:username, "is taken.") if username_taken
  end

  def non_banished_username
    errors.add(:username, "has been banished.") if BanishedUser.exists?(username: username)
  end

  def banished?
    username.starts_with?("spam_")
  end

  def subscribe_to_mailchimp_newsletter
    return unless email.present? && email.include?("@")
    return if saved_changes["unconfirmed_email"] && saved_changes["confirmation_sent_at"]
    return unless saved_changes.key?(:email) || saved_changes.key?(:email_newsletter)

    Users::SubscribeToMailchimpNewsletterWorker.perform_async(id)
  end

  def a_sustaining_member?
    monthly_dues.positive?
  end

  def resave_articles
    articles.find_each do |article|
      if article.path
        CacheBuster.bust(article.path)
        CacheBuster.bust("#{article.path}?i=i")
      end
      article.save
    end
  end

  def settings_tab_list
    %w[
      Profile
      UX
      Integrations
      Notifications
      Publishing\ from\ RSS
      Organization
      Response\ Templates
      Billing
      Account
      Misc
    ]
  end

  def profile_image_90
    ProfileImage.new(self).get(width: 90)
  end

  def unsubscribe_from_newsletters
    return if email.blank?

    MailchimpBot.new(self).unsubscribe_all_newsletters
  end

  def auditable?
    trusted || tag_moderator? || any_admin?
  end

  def tag_moderator?
    roles.where(name: "tag_moderator").any?
  end

  def currently_streaming?
    currently_streaming_on.present?
  end

  def currently_streaming_on_twitch?
    currently_streaming_on == "twitch"
  end

  def enough_credits?(num_credits_needed)
    credits.unspent.size >= num_credits_needed
  end

  def receives_follower_email_notifications?
    email.present? &&
      email_follower_notifications
  end

  def hotness_score
    search_score
  end

  def authenticated_through?(provider_name)
    return false unless Authentication::Providers.available?(provider_name)
    return false unless Authentication::Providers.enabled?(provider_name)

    identities_enabled.exists?(provider: provider_name)
  end

  def authenticated_with_all_providers?
    identities_enabled.pluck(:provider).map(&:to_sym) == Authentication::Providers.enabled
  end

  def rate_limiter
    RateLimitChecker.new(self)
  end

  def flipper_id
    "User:#{id}"
  end

  private

  def estimate_default_language
    Users::EstimateDefaultLanguageWorker.perform_async(id)
  end

  def set_default_language
    language_settings["preferred_languages"] ||= ["en"]
  end

  def send_welcome_notification
    return unless (set_up_profile_broadcast = Broadcast.active.find_by(title: "Welcome Notification: set_up_profile"))

    Notification.send_welcome_notification(id, set_up_profile_broadcast.id)
  end

  def verify_twitter_username
    self.twitter_username = nil if twitter_username == ""
  end

  def verify_github_username
    self.github_username = nil if github_username == ""
  end

  def verify_email
    self.email = nil if email == ""
  end

  def verify_twitch_username
    self.twitch_username = nil if twitch_username == ""
  end

  def set_username
    set_temp_username if username.blank?
    self.username = username&.downcase
  end

  def set_temp_username
    self.username = if temp_name_exists?
                      temp_username + "_" + rand(100).to_s
                    else
                      temp_username
                    end
  end

  def temp_name_exists?
    User.exists?(username: temp_username) || Organization.exists?(slug: temp_username)
  end

  def temp_username
    if twitter_username
      twitter_username.downcase.gsub(/[^0-9a-z_]/i, "").delete(" ")
    elsif github_username
      github_username.downcase.gsub(/[^0-9a-z_]/i, "").delete(" ")
    end
  end

  def downcase_email
    self.email = email.downcase if email
  end

  def set_config_input
    self.config_theme = config_theme.tr(" ", "_")
    self.config_font = config_font.tr(" ", "_")
    self.config_navbar = config_navbar.tr(" ", "_")
  end

  def check_for_username_change
    return unless username_changed?

    self.old_old_username = old_username
    self.old_username = username_was
    chat_channels.find_each do |channel|
      channel.slug = channel.slug.gsub(username_was, username)
      channel.save
    end
    articles.find_each do |article|
      article.path = article.path.gsub(username_was, username)
      article.save
    end
  end

  def conditionally_resave_articles
    Users::ResaveArticlesWorker.perform_async(id) if core_profile_details_changed? && !banned
  end

  def bust_cache
    Users::BustCacheWorker.perform_async(id)
  end

  def core_profile_details_changed?
    saved_change_to_username? ||
      saved_change_to_name? ||
      saved_change_to_summary? ||
      saved_change_to_bg_color_hex? ||
      saved_change_to_text_color_hex? ||
      saved_change_to_profile_image? ||
      saved_change_to_github_username? ||
      saved_change_to_twitter_username?
  end

  def conditionally_validate_summary
    # Grandfather people who had a too long summary before.
    return if summary_was && summary_was.size > 200

    errors.add(:summary, "is too long.") if summary.present? && summary.size > 200
  end

  def validate_feed_url
    return if feed_url.blank?
    return if RssReader.new.valid_feed_url?(feed_url)

    errors.add(:feed_url, "is not a valid RSS/Atom feed")
  end

  def validate_mastodon_url
    return if mastodon_url.blank?

    uri = URI.parse(mastodon_url)
    return if uri.host&.in?(Constants::ALLOWED_MASTODON_INSTANCES)

    errors.add(:mastodon_url, "is not an allowed Mastodon instance")
  rescue URI::InvalidURIError
    errors.add(:mastodon_url, "is not a valid URL")
  end

  def tag_keywords_for_search
    "#{employer_name}#{mostly_work_with}#{available_for}"
  end

  def search_score
    counts_score = (articles_count + comments_count + reactions_count + badge_achievements_count) * 10
    score = (counts_score + tag_keywords_for_search.size) * reputation_modifier
    score.to_i
  end

  def destroy_follows
    follower_relationships = Follow.followable_user(id)
    follower_relationships.destroy_all
    follows.destroy_all
  end

  def index_roles(_role)
    index_to_elasticsearch_inline
  end

  def can_send_confirmation_email
    return if changes[:email].blank? || id.blank?

    rate_limiter.track_limit_by_action(:send_email_confirmation)
    rate_limiter.check_limit!(:send_email_confirmation)
  rescue RateLimitChecker::LimitReached => e
    errors.add(:email, "confirmation could not be sent. #{e.message}")
  end

  def update_rate_limit
    return unless persisted?

    rate_limiter.track_limit_by_action(:user_update)
    rate_limiter.check_limit!(:user_update)
  rescue RateLimitChecker::LimitReached => e
    errors.add(:base, "User could not be saved. #{e.message}")
  end
end
