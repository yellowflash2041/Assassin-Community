require_relative "../lib/acts_as_taggable_on/tag.rb"

class Tag < ActsAsTaggableOn::Tag
  attr_accessor :points

  acts_as_followable
  resourcify

  ALLOWED_CATEGORIES = %w[uncategorized language library tool site_mechanic location subcommunity].freeze

  attr_accessor :tag_moderator_id, :remove_moderator_id

  belongs_to :badge, optional: true
  has_one :sponsorship, as: :sponsorable, inverse_of: :sponsorable, dependent: :destroy

  mount_uploader :profile_image, ProfileImageUploader
  mount_uploader :social_image, ProfileImageUploader

  validates :text_color_hex,
            format: /\A#([A-Fa-f0-9]{6}|[A-Fa-f0-9]{3})\z/, allow_nil: true
  validates :bg_color_hex,
            format: /\A#([A-Fa-f0-9]{6}|[A-Fa-f0-9]{3})\z/, allow_nil: true
  validates :category, inclusion: { in: ALLOWED_CATEGORIES }

  validate :validate_alias_for, if: :alias_for?
  validate :validate_name, if: :name?

  before_validation :evaluate_markdown
  before_validation :pound_it

  before_save :calculate_hotness_score
  before_save :mark_as_updated

  after_commit :bust_cache
  after_commit :index_to_elasticsearch, on: %i[create update]
  after_commit :remove_from_elasticsearch, on: [:destroy]

  include Searchable
  SEARCH_SERIALIZER = Search::TagSerializer
  SEARCH_CLASS = Search::Tag

  # possible social previews templates for articles with a particular tag
  def self.social_preview_templates
    Rails.root.join("app/views/social_previews/articles").children.map { |ch| File.basename(ch, ".html.erb") }
  end

  def submission_template_customized(param_0 = nil)
    submission_template&.gsub("PARAM_0", param_0)
  end

  def tag_moderator_ids
    User.with_role(:tag_moderator, self).order("id ASC").pluck(:id)
  end

  def self.bufferized_tags
    Rails.cache.fetch("bufferized_tags_cache", expires_in: 2.hours) do
      where.not(buffer_profile_id_code: nil).pluck(:name)
    end
  end

  def self.valid_categories
    ALLOWED_CATEGORIES
  end

  def self.aliased_name(word)
    tag = find_by(name: word.downcase)
    return unless tag

    tag.alias_for.presence || tag.name
  end

  def validate_name
    errors.add(:name, "is too long (maximum is 30 characters)") if name.length > 30
    errors.add(:name, "contains non-alphanumeric characters") unless name.match?(/\A[[:alnum:]]+\z/)
  end

  def mod_chat_channel
    ChatChannel.find(mod_chat_channel_id) if mod_chat_channel_id
  end

  private

  def evaluate_markdown
    self.rules_html = MarkdownParser.new(rules_markdown).evaluate_markdown
    self.wiki_body_html = MarkdownParser.new(wiki_body_markdown).evaluate_markdown
  end

  def calculate_hotness_score
    self.hotness_score = Article.tagged_with(name).
      where("articles.featured_number > ?", 7.days.ago.to_i).
      map do |article|
        (article.comments_count * 14) + article.score + rand(6) + ((taggings_count + 1) / 2)
      end.
      sum
  end

  def bust_cache
    Tags::BustCacheWorker.perform_async(name)
  end

  def validate_alias_for
    return if Tag.exists?(name: alias_for)

    errors.add(:tag, "alias_for must refer to an existing tag")
  end

  def pound_it
    text_color_hex&.prepend("#") unless text_color_hex&.starts_with?("#") || text_color_hex.blank?
    bg_color_hex&.prepend("#") unless bg_color_hex&.starts_with?("#") || bg_color_hex.blank?
  end

  def mark_as_updated
    self.updated_at = Time.current # Acts-as-taggable didn't come with this by default
  end
end
