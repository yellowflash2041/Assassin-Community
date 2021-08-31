class Profile < ApplicationRecord
  belongs_to :user

  validates :user_id, uniqueness: true
  validates :location, :website_url, length: { maximum: 100 }
  validates :website_url, url: { allow_blank: true, no_local: true, schemes: %w[https http] }
  validates_with ProfileValidator

  # Static fields are columns on the profiles table; they have no relationship
  # to a ProfileField record. These are columns we can safely assume exist for
  # any profile on a given Forem.
  STATIC_FIELDS = %w[summary location website_url].freeze

  # Generates typed accessors for all currently defined profile fields.
  def self.refresh_attributes!
    return if ENV["ENV_AVAILABLE"] == "false"
    return unless table_exists?

    ProfileField.find_each do |field|
      store_attribute :data, field.attribute_name.to_sym, field.type
    end
  end

  # Set up all profile attributes when this class loads so all store_attribute
  # accessors get defined immediately.
  refresh_attributes!

  # Returns an array of all currently defined `store_attribute`s on `data`.
  def self.attributes
    (stored_attributes[:data] || []).map(&:to_s)
  end

  def self.static_fields
    STATIC_FIELDS
  end

  def clear!
    update(data: {})
  end
end
