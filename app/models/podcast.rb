class Podcast < ApplicationRecord
  has_many :podcast_episodes

  mount_uploader :image, ProfileImageUploader
  mount_uploader :pattern_image, ProfileImageUploader

  validates :main_color_hex, :title, :feed_url, :image, presence: true
  validates :feed_url, uniqueness: true
  validates :slug,
            presence: true,
            uniqueness: true,
            format: { with: /\A[a-zA-Z0-9\-_]+\Z/ },
            exclusion: { in: ReservedWords.all, message: "slug is reserved" }
  validate :unique_slug_including_users_and_orgs, if: :slug_changed?

  after_save :bust_cache

  alias_attribute :path, :slug
  alias_attribute :profile_image_url, :image_url
  alias_attribute :name, :title

  private

  def unique_slug_including_users_and_orgs
    errors.add(:slug, "is taken.") if User.find_by(username: slug) || Organization.find_by(slug: slug) || Page.find_by(slug: slug)
  end

  def bust_cache
    return unless path

    CacheBuster.new.bust("/" + path)
  end
end
