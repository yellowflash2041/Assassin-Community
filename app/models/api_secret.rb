class ApiSecret < ApplicationRecord
  has_secure_token :secret

  belongs_to :user

  validates :description, presence: true, length: { maximum: 300 }
end
