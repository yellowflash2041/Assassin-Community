module RateLimitCheckerHelper
  CONFIGURABLE_RATES = {
    rate_limit_follow_count_daily: {
      min: 0,
      placeholder: 500,
      description: "The number of users a person can follow daily"
    },
    rate_limit_comment_creation: {
      min: 0,
      placeholder: 9,
      description: "The number of comments a user can create within 30 seconds"
    },
    rate_limit_listing_creation: {
      min: 1,
      placeholder: 1,
      description: "The number of listings a user can create in 1 minute"
    },
    rate_limit_published_article_creation: {
      min: 0,
      placeholder: 9,
      description: "The number of articles a user can create within 30 seconds"
    },
    rate_limit_image_upload: {
      min: 0,
      placeholder: 9,
      description: "The number of images a user can upload within 30 seconds"
    },
    rate_limit_email_recipient: {
      min: 0,
      placeholder: 5,
      description: "The number of emails we send to a user within 2 minutes"
    },
    rate_limit_organization_creation: {
      min: 1,
      placeholder: 1,
      description: "The number of organizations a user can create within a 5 minute period"
    },
    rate_limit_reaction_creation: {
      min: 1,
      placeholder: 10,
      description: "The number of times a user can react in a 30 second period"
    }
  }.freeze

  def configurable_rate_limits
    CONFIGURABLE_RATES
  end
end
