class Collection < ApplicationRecord
  has_many :articles
  belongs_to :user, optional: true
  belongs_to :organization, optional: true

  validates :user_id, presence: true
  validates :slug, uniqueness: { scope: :user_id }

  def self.find_series(slug, user)
    Collection.find_or_create_by(slug: slug, user: user)
  end
end
