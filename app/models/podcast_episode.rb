class PodcastEpisode < ApplicationRecord
  self.ignored_columns = %w[
    duration_in_seconds
  ]

  include Searchable
  SEARCH_SERIALIZER = Search::PodcastEpisodeSerializer
  SEARCH_CLASS = Search::FeedContent

  acts_as_taggable

  delegate :slug, to: :podcast, prefix: true
  delegate :image_url, to: :podcast, prefix: true
  delegate :title, to: :podcast, prefix: true
  delegate :published, to: :podcast

  belongs_to :podcast
  has_many :comments, as: :commentable, inverse_of: :commentable

  mount_uploader :image, ProfileImageUploader
  mount_uploader :social_image, ProfileImageUploader

  validates :title, presence: true
  validates :slug, presence: true
  validates :media_url, presence: true, uniqueness: true
  validates :guid, presence: true, uniqueness: true

  # NOTE: Any create callbacks will not be run since we use activerecord-import to create episodes
  # https://github.com/zdennis/activerecord-import#callbacks
  after_update :purge
  after_destroy :purge, :purge_all
  after_save :bust_cache

  after_commit :index_to_elasticsearch, on: %i[update]
  after_commit :remove_from_elasticsearch, on: [:destroy]

  before_validation :process_html_and_prefix_all_images

  scope :reachable, -> { where(reachable: true) }
  scope :published, -> { joins(:podcast).where(podcasts: { published: true }) }
  scope :available, -> { reachable.published }
  scope :for_user, lambda { |user|
    joins(:podcast).where(podcasts: { creator_id: user.id })
  }
  scope :eager_load_serialized_data, -> {}

  def search_id
    "podcast_episode_#{id}"
  end

  def comments_blob
    comments.pluck(:body_markdown).join(" ")
  end

  def path
    return unless podcast&.slug

    "/#{podcast.slug}/#{slug}"
  end

  def description
    ActionView::Base.full_sanitizer.sanitize(body)
  end

  def profile_image_url
    image_url || "http://41orchard.com/wp-content/uploads/2011/12/Robot-Chalkboard-Decal.gif"
  end

  def body_text
    ActionView::Base.full_sanitizer.sanitize(processed_html)
  end

  def zero_method
    0
  end
  alias hotness_score zero_method
  alias search_score zero_method
  alias public_reactions_count zero_method

  def class_name
    self.class.name
  end

  def tag_keywords_for_search
    tags.pluck(:keywords_for_search).join
  end

  ## Useless stubs
  def nil_method
    nil
  end
  alias user_id nil_method
  alias second_user_id nil_method
  alias third_user_id nil_method

  private

  def bust_cache
    PodcastEpisodes::BustCacheWorker.perform_async(id, path, podcast_slug)
  end

  def process_html_and_prefix_all_images
    return if body.blank?

    self.processed_html = body.
      gsub("\r\n<p>&nbsp;</p>\r\n", "").gsub("\r\n<p>&nbsp;</p>\r\n", "").
      gsub("\r\n<h3>&nbsp;</h3>\r\n", "").gsub("\r\n<h3>&nbsp;</h3>\r\n", "")

    self.processed_html = "<p>#{processed_html}</p>" unless processed_html.include?("<p>")

    doc = Nokogiri::HTML(processed_html)
    doc.css("img").each do |img|
      img_src = img.attr("src")

      if img_src
        quality = "auto"
        quality = 66 if img_src.include?(".gif")

        cloudinary_img_src = ActionController::Base.helpers.
          cl_image_path(img_src,
                        type: "fetch",
                        width: 725,
                        crop: "limit",
                        quality: quality,
                        flags: "progressive",
                        fetch_format: "auto",
                        sign_url: true)
        self.processed_html = processed_html.gsub(img_src, cloudinary_img_src)
      end
    end
  end
end
