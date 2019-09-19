module Webhook
  class Endpoint < ApplicationRecord
    belongs_to :user, inverse_of: :webhook_endpoints
    belongs_to :oauth_application, optional: true,
                                   class_name: "Doorkeeper::Application",
                                   foreign_key: :oauth_application_id,
                                   inverse_of: :webhook_endpoints

    validates :target_url, presence: true, uniqueness: true, url: { schemes: %w[https] }
    validates :source, :events, presence: true

    attribute :events, :string, array: true, default: []

    scope :for_events, ->(events) { where("events @> ARRAY[?]::varchar[]", Array(events)) }
    scope :for_app, ->(app_id) { where(oauth_application_id: app_id) }

    def self.table_name_prefix
      "webhook_"
    end

    def events=(events)
      events = Array(events).map { |event| event.to_s.underscore }
      super(Webhook::Event::EVENT_TYPES & events)
    end
  end
end
