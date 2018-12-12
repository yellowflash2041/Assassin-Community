class Reaction < ApplicationRecord
  CATEGORIES = %w(like readinglist unicorn thinking hands thumbsdown vomit).freeze

  belongs_to :reactable, polymorphic: true
  belongs_to :user

  counter_culture :reactable,
    column_name: proc { |model|
      model.points.positive? ? "positive_reactions_count" : "reactions_count"
    }
  counter_culture :user

  validates :category, inclusion: { in: CATEGORIES }
  validates :reactable_type, inclusion: { in: %w(Comment Article) }
  validates :status, inclusion: { in: %w(valid invalid confirmed) }
  validates :user_id, uniqueness: { scope: %i[reactable_id reactable_type category] }
  validate  :permissions

  before_save :assign_points
  after_save :update_reactable, :async_bust
  before_destroy :update_reactable, :clean_up_before_destroy

  class << self
    def count_for_article(id)
      Rails.cache.fetch("count_for_reactable-Article-#{id}", expires_in: 1.hour) do
        reactions = Reaction.where(reactable_id: id, reactable_type: "Article")
        %w(like readinglist unicorn).map do |type|
          { category: type, count: reactions.where(category: type).size }
        end
      end
    end

    def for_display(user)
      includes(:reactable).
        where(reactable_type: "Article", user: user).
        where("created_at > ?", 5.days.ago).
        select("distinct on (reactable_id) *").
        take(15)
    end

    def cached_any_reactions_for?(reactable, user, category)
      cache_name = "any_reactions_for-#{reactable.class.name}-#{reactable.id}-#{user.updated_at}-#{category}"
      Rails.cache.fetch(cache_name, expires_in: 24.hours) do
        Reaction.where(reactable: reactable, user: user, category: category).any?
      end
    end
  end

  private

  def update_reactable
    if destroyed?
      Reaction::UpdateRecordsJob.perform_now(reactable, user)
    else
      Reaction::UpdateRecordsJob.perform_later(reactable, user)
    end
  end

  def async_bust
    featured_articles = Article.where(featured: true).order("hotness_score DESC").limit(3).pluck(:id)
    if featured_articles.include?(reactable.id)
      reactable.touch
      cache_buster = CacheBuster.new
      cache_buster.bust "/"
      cache_buster.bust "/"
      cache_buster.bust "/?i=i"
      cache_buster.bust "?i=i"
    end
  end
  handle_asynchronously :async_bust

  def clean_up_before_destroy
    reactable.index! if reactable_type == "Article"
  end

  BASE_POINTS = {
    "vomit" => -50.0,
    "thumbsdown" => -10.0
  }.freeze

  def assign_points
    base_points = BASE_POINTS.fetch(category, 1.0)
    base_points = 0 if status == "invalid"
    base_points = base_points * 2 if status == "confirmed"
    self.points = user ? (base_points * user.reputation_modifier) : -5
  end

  def permissions
    if negative_reaction_from_untrusted_user?
      errors.add(:category, "is not valid.")
    end

    if reactable_type == "Article" && !reactable&.published
      errors.add(:reactable_id, "is not valid.")
    end
  end

  def negative_reaction_from_untrusted_user?
    negative? && !user.trusted
  end

  def negative?
    category == "vomit" || category == "thumbsdown"
  end
end
