class DisplayAd < ApplicationRecord
  belongs_to :organization
  has_many :display_ad_events

  validates :organization_id, presence: true
  validates :placement_area, presence: true,
                             inclusion: { in: %w[sidebar_left sidebar_right] }
  validates :body_markdown, presence: true
  before_save :process_markdown

  scope :approved_and_published, -> { where(approved: true, published: true) }

  def self.for_display(area)
    if rand(8) == 1
      approved_and_published.where(placement_area: area).order("success_rate DESC").sample
    else
      approved_and_published.where(placement_area: area).order("success_rate DESC").limit(rand(1..15)).sample
    end
  end

  private

  def process_markdown
    renderer = Redcarpet::Render::HTMLRouge.new(hard_wrap: true, filter_html: false)
    markdown = Redcarpet::Markdown.new(renderer)
    initial_html = markdown.render(body_markdown)
    stripped_html = ActionController::Base.helpers.sanitize initial_html.html_safe,
                                                            tags: %w[a em i b u br img h1 h2 h3 h4 div],
                                                            attributes: %w[href target src height width style]
    html = stripped_html.delete("\n")
    self.processed_html = MarkdownParser.new(html).prefix_all_images(html, 350)
  end
end
