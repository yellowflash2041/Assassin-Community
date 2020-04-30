class ClassifiedListing < ApplicationRecord
  self.ignored_columns = ["category"]

  include Searchable

  SEARCH_SERIALIZER = Search::ClassifiedListingSerializer
  SEARCH_CLASS = Search::ClassifiedListing

  attr_accessor :action

  # Note: categories were hardcoded at first and this model was only added later,
  # so the association name is a bit verbose since the original "category" attribute
  # was kept to minimize code changes.
  belongs_to :classified_listing_category
  belongs_to :user
  belongs_to :organization, optional: true
  before_save :evaluate_markdown
  before_create :create_slug
  before_validation :modify_inputs
  after_commit :index_to_elasticsearch, on: %i[create update]
  after_commit :remove_from_elasticsearch, on: [:destroy]
  acts_as_taggable_on :tags
  has_many :credits, as: :purchase, inverse_of: :purchase, dependent: :nullify

  validates :user_id, presence: true
  validates :organization_id, presence: true, unless: :user_id?

  validates :title, presence: true, length: { maximum: 128 }
  validates :body_markdown, presence: true, length: { maximum: 400 }
  validates :location, length: { maximum: 32 }
  validate :restrict_markdown_input
  validate :validate_tags

  scope :published, -> { where(published: true) }
  scope :in_category, lambda { |slug|
    joins(:classified_listing_category).
      where("classified_listing_categories.slug" => slug)
  }

  delegate :cost, to: :classified_listing_category

  def category
    classified_listing_category&.slug
  end

  def author
    organization || user
  end

  def path
    "/listings/#{category}/#{slug}"
  end

  def natural_expiration_date
    (bumped_at || created_at) + 30.days
  end

  private

  def evaluate_markdown
    self.processed_html = MarkdownParser.new(body_markdown).evaluate_listings_markdown
  end

  def modify_inputs
    ActsAsTaggableOn::Taggable::Cache.included(ClassifiedListing)
    ActsAsTaggableOn.default_parser = ActsAsTaggableOn::TagParser
    self.body_markdown = body_markdown.to_s.gsub(/\r\n/, "\n")
  end

  def restrict_markdown_input
    markdown_string = body_markdown.to_s
    errors.add(:body_markdown, "has too many linebreaks. No more than 12 allowed.") if markdown_string.scan(/(?=\n)/).count > 12
    errors.add(:body_markdown, "is not allowed to include images.") if markdown_string.include?("![")
    errors.add(:body_markdown, "is not allowed to include liquid tags.") if markdown_string.include?("{% ")
  end

  def validate_tags
    errors.add(:tag_list, "exceed the maximum of 8 tags") if tag_list.length > 8
  end

  def create_slug
    self.slug = "#{title.downcase.parameterize.delete('_')}-#{rand(100_000).to_s(26)}"
  end
end
