class Organization < ApplicationRecord
  include CloudinaryHelper

  COLOR_HEX_REGEXP = /\A#([A-Fa-f0-9]{6}|[A-Fa-f0-9]{3})\z/.freeze
  INTEGER_REGEXP = /\A\d+\z/.freeze
  SLUG_REGEXP = /\A[a-zA-Z0-9\-_]+\z/.freeze
  MESSAGES = {
    integer_only: "Integer only. No sign allowed.",
    reserved_word: "%<value>s is a reserved word. Contact site admins for help registering your organization."
  }.freeze

  acts_as_followable

  has_many :api_secrets, through: :users
  has_many :articles
  has_many :classified_listings
  has_many :collections
  has_many :credits
  has_many :display_ads
  has_many :notifications
  has_many :organization_memberships, dependent: :delete_all
  has_many :profile_pins, as: :profile, inverse_of: :profile
  has_many :sponsorships
  has_many :unspent_credits, -> { where spent: false }, class_name: "Credit", inverse_of: :organization
  has_many :users, through: :organization_memberships

  validates :bg_color_hex, format: COLOR_HEX_REGEXP, allow_blank: true
  validates :company_size, format: { with: INTEGER_REGEXP, message: MESSAGES[:integer_only], allow_blank: true }
  validates :company_size, length: { maximum: 7 }, allow_nil: true
  validates :cta_body_markdown, length: { maximum: 256 }
  validates :cta_button_text, length: { maximum: 20 }
  validates :cta_button_url, length: { maximum: 150 }, url: { allow_blank: true, no_local: true }
  validates :github_username, length: { maximum: 50 }
  validates :location, :email, length: { maximum: 64 }
  validates :name, :summary, :url, :profile_image, presence: true
  validates :name, length: { maximum: 50 }
  validates :proof, length: { maximum: 1500 }
  validates :secret, length: { is: 100 }, uniqueness: { allow_blank: true }, allow_blank: true
  validates :slug, exclusion: { in: ReservedWords.all, message: MESSAGES[:reserved_word] }
  validates :slug, format: { with: SLUG_REGEXP }, length: { in: 2..18 }
  validates :slug, presence: true, uniqueness: { case_sensitive: false }
  validates :summary, length: { maximum: 250 }
  validates :tag_line, length: { maximum: 60 }
  validates :tech_stack, :story, length: { maximum: 640 }
  validates :text_color_hex, format: COLOR_HEX_REGEXP, allow_blank: true
  validates :twitter_username, length: { maximum: 15 }
  validates :url, length: { maximum: 200 }, url: { allow_blank: true, no_local: true }

  validate :unique_slug_including_users_and_podcasts, if: :slug_changed?

  after_save :bust_cache
  before_save :generate_secret
  before_save :remove_at_from_usernames
  before_save :update_articles
  before_validation :check_for_slug_change
  before_validation :downcase_slug
  before_validation :evaluate_markdown

  after_commit :sync_related_elasticsearch_docs, on: %i[update destroy]

  mount_uploader :profile_image, ProfileImageUploader
  mount_uploader :nav_image, ProfileImageUploader
  mount_uploader :dark_nav_image, ProfileImageUploader

  alias_attribute :username, :slug
  alias_attribute :old_username, :old_slug
  alias_attribute :old_old_username, :old_old_slug
  alias_attribute :website_url, :url

  def check_for_slug_change
    return unless slug_changed?

    self.old_old_slug = old_slug
    self.old_slug = slug_was
    Organizations::UpdateOrganizationArticlesPathsWorker.perform_async(id, slug_was, slug)
  end

  def path
    "/#{slug}"
  end

  def generate_secret
    self.secret = generated_random_secret if secret.blank?
  end

  def generated_random_secret
    SecureRandom.hex(50)
  end

  def approved_and_filled_out_cta?
    cta_processed_html?
  end

  def profile_image_90
    ProfileImage.new(self).get(width: 90)
  end

  def enough_credits?(num_credits_needed)
    credits.unspent.size >= num_credits_needed
  end

  def pro?
    false
  end

  def banned
    false
  end

  private

  def evaluate_markdown
    self.cta_processed_html = MarkdownParser.new(cta_body_markdown).evaluate_limited_markdown
  end

  def remove_at_from_usernames
    self.twitter_username = twitter_username.delete("@") if twitter_username
    self.github_username = github_username.delete("@") if github_username
  end

  def downcase_slug
    self.slug = slug&.downcase
  end

  def update_articles
    return unless saved_change_to_slug || saved_change_to_name || saved_change_to_profile_image

    cached_org_object = {
      name: name,
      username: username,
      slug: slug,
      profile_image_90: profile_image_90,
      profile_image_url: profile_image_url
    }
    articles.update(cached_organization: OpenStruct.new(cached_org_object))
  end

  def bust_cache
    Organizations::BustCacheWorker.perform_async(id, slug)
  end

  def unique_slug_including_users_and_podcasts
    slug_taken = (
      User.exists?(username: slug) ||
      Podcast.exists?(slug: slug) ||
      Page.exists?(slug: slug) ||
      slug&.include?("sitemap-")
    )

    errors.add(:slug, "is taken.") if slug_taken
  end

  def sync_related_elasticsearch_docs
    DataSync::Elasticsearch::Organization.new(self).call
  end
end
