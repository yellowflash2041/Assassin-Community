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

  scope :reachable, -> { where(id: PodcastEpisode.reachable.select(:podcast_id)) }

  alias_attribute :path, :slug
  alias_attribute :profile_image_url, :image_url
  alias_attribute :name, :title

  def existing_episode(item)
    episode = PodcastEpisode.where(media_url: item.enclosure_url).
      or(PodcastEpisode.where(title: item.title)).
      or(PodcastEpisode.where(guid: item.guid.to_s)).presence
    episode ||= PodcastEpisode.where(website_url: item.link).presence if unique_website_url?
    episode.to_a.first
  end

  private

  def unique_slug_including_users_and_orgs
    errors.add(:slug, "is taken.") if User.find_by(username: slug) || Organization.find_by(slug: slug) || Page.find_by(slug: slug)
  end

  def bust_cache
    return unless path

    Podcasts::BustCacheJob.perform_later(path)
  end
end
