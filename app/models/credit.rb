class Credit < ApplicationRecord
  attr_accessor :number_to_purchase

  belongs_to    :user, optional: true
  belongs_to    :organization, optional: true

  counter_culture :user # Only counting credits_count right now. TODO: spent_credits_count and unspent_credits_count (counter culture gem)
  counter_culture :organization # Only counting credits_count right now. TODO: spent_credits_count and unspent_credits_count (counter culture gem)

  def self.add_to(user, amount)
    credit_objects = []
    amount.times do
      credit_objects << Credit.new(user_id: user.id)
    end
    Credit.import credit_objects
  end

  def self.remove_from(user, amount)
    user.credits.where(spent: false).limit(amount).delete_all
  end

  def self.add_to_org(org, amount)
    credit_objects = []
    amount.times do
      credit_objects << Credit.new(organization_id: org.id)
    end
    Credit.import credit_objects
  end

  def self.remove_from_org(org, amount)
    org.credits.where(spent: false).limit(amount).delete_all
  end
end
