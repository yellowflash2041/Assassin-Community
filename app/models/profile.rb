class Profile < ApplicationRecord
  belongs_to :user

  # This method generates typed accessors for all active profile fields
  def self.define_store_accessors!
    ProfileField.active.find_each do |field|
      store_attribute :data, field.attribute_name, field.type
    end
  end

  define_store_accessors!

  validates :data, presence: true
end
