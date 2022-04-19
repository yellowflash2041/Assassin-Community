module Articles
  module Feeds
    # The default number of days old that an article can be for us
    # to consider it in the relevance feed.
    #
    # @note I believe that it is likely we would extract this constant
    #       into an administrative setting.  Hence, I want to keep it
    #       a scalar.
    DEFAULT_DAYS_SINCE_PUBLISHED = 7

    # @note I believe that it is likely we would extract this constant
    #       into an administrative setting.  Hence, I want to keep it
    #       a scalar to ease the implementation details of the admin
    #       setting.
    NUMBER_OF_HOURS_TO_OFFSET_USERS_LATEST_ARTICLE_VIEWS = 18

    # @api private
    #
    # This method helps answer the question: What are the articles
    # that I should consider as new for the given user?  This method
    # provides a date by which to filter out "stale to the user"
    # articles.
    #
    # @note Do we need to continue using this method?  It's part of
    #       the hot story grab experiment that we ran with the
    #       Article::Feeds::LargeForemExperimental, but may not be
    #       relevant.
    #
    # @param user [User]
    # @param days_since_published [Integer] if someone
    #        hasn't viewed any articles, give them things from the
    #        database seeds.
    #
    # @return [ActiveSupport::TimeWithZone]
    #
    # @note the days_since_published is something carried
    #       over from the LargeForemExperimental and may not be
    #       relevant given that we have the :daily_factor_decay.
    #       However, this further limitation based on a user's
    #       second most recent page view helps further winnow down
    #       the result set.
    def self.oldest_published_at_to_consider_for(user:, days_since_published: DEFAULT_DAYS_SINCE_PUBLISHED)
      time_of_second_latest_page_view = user&.page_views&.second_to_last&.created_at
      return days_since_published.days.ago unless time_of_second_latest_page_view

      time_of_second_latest_page_view - NUMBER_OF_HOURS_TO_OFFSET_USERS_LATEST_ARTICLE_VIEWS.hours
    end

    # The available feed levers for this Forem instance.
    #
    # @return [Articles::Feeds::LeverCatalogBuilder]
    def self.lever_catalog
      LEVER_CATALOG
    end

    # rubocop:disable Metrics/BlockLength
    # The available levers for this forem instance.
    LEVER_CATALOG = LeverCatalogBuilder.new do
      order_by_lever(OrderByLever::DEFAULT_KEY,
                     label: "Order by highest calculated relevancy score then latest published at time.",
                     order_by_fragment: "article_relevancies.relevancy_score DESC, articles.published_at DESC")

      order_by_lever(:final_order_by_random_weighted_to_score,
                     label: "Order by conflating a random number and the score (see forem/forem#16128)",
                     order_by_fragment: "RANDOM() ^ (1.0 / greatest(articles.score, 0.1)) DESC")

      relevancy_lever(:comments_count_by_those_followed,
                      label: "Weight to give for the number of comments on the article from other users" \
                             "that the given user follows.",
                      user_required: true,
                      select_fragment: "COUNT(comments_by_followed.id)",
                      joins_fragment: ["LEFT OUTER JOIN follows AS followed_user
                                          ON articles.user_id = followed_user.followable_id
                                            AND followed_user.followable_type = 'User'
                                            AND followed_user.follower_id = :user_id
                                            AND followed_user.follower_type = 'User'",
                                       "LEFT OUTER JOIN comments AS comments_by_followed
                                          ON comments_by_followed.commentable_id = articles.id
                                            AND comments_by_followed.commentable_type = 'Article'
                                            AND followed_user.followable_id = comments_by_followed.user_id
                                            AND followed_user.followable_type = 'User'
                                            AND comments_by_followed.deleted = false
                                            AND comments_by_followed.created_at > :oldest_published_at"])

      relevancy_lever(:comments_count,
                      label: "Weight to give to the number of comments on the article.",
                      user_required: false,
                      select_fragment: "articles.comments_count",
                      group_by_fragment: "articles.comments_count")

      relevancy_lever(:daily_decay,
                      label: "Weight given based on the relative age of the article",
                      user_required: true,
                      select_fragment: "(current_date - articles.published_at::date)",
                      group_by_fragment: "articles.published_at")

      relevancy_lever(:experience,
                      label: "Weight to give based on the difference between experience level of the " \
                             "article and given user.",
                      user_required: true,
                      select_fragment: "ROUND(ABS(articles.experience_level_rating - (SELECT
                                          (CASE
                                             WHEN experience_level IS NULL THEN :default_user_experience_level
                                             ELSE experience_level END ) AS user_experience_level
                                          FROM users_settings WHERE users_settings.user_id = :user_id)))",
                      group_by_fragment: "articles.experience_level_rating")

      relevancy_lever(:featured_article,
                      label: "Weight to give for feature or unfeatured articles.  1 is featured.",
                      user_required: false,
                      select_fragment: "(CASE articles.featured WHEN true THEN 1 ELSE 0 END)",
                      group_by_fragment: "articles.featured")

      relevancy_lever(:following_author,
                      label: "Weight to give when the given user follows the article's author." \
                             "1 is followed, 0 is not followed.",
                      user_required: true,
                      select_fragment: "COUNT(followed_user.follower_id)",
                      joins_fragment: ["LEFT OUTER JOIN follows AS followed_user
                                          ON articles.user_id = followed_user.followable_id
                                            AND followed_user.followable_type = 'User'
                                            AND followed_user.follower_id = :user_id
                                            AND followed_user.follower_type = 'User'"])

      relevancy_lever(:following_org,
                      label: "Weight to give to the when the given user follows the article's organization." \
                             "1 is followed, 0 is not followed.",
                      user_required: true,
                      select_fragment: "COUNT(followed_org.follower_id)",
                      joins_fragment: ["LEFT OUTER JOIN follows AS followed_org
                                          ON articles.organization_id = followed_org.followable_id
                                            AND followed_org.followable_type = 'Organization'
                                            AND followed_org.follower_id = :user_id
                                            AND followed_org.follower_type = 'User'"])

      relevancy_lever(:latest_comment,
                      label: "Weight to give an article based on it's most recent comment.",
                      user_required: false,
                      select_fragment: "(current_date - MAX(comments.created_at)::date)",
                      joins_fragment: ["LEFT OUTER JOIN comments
                                          ON comments.commentable_id = articles.id
                                            AND comments.commentable_type = 'Article'
                                            AND comments.deleted = false
                                            AND comments.created_at > :oldest_published_at"])

      relevancy_lever(:matching_tags,
                      label: "Weight to give for the sum points of the intersecting tags of the article" \
                             "user positive follows.",
                      user_required: true,
                      select_fragment: "LEAST(10.0, SUM(followed_tags.points))::integer",
                      joins_fragment: ["LEFT OUTER JOIN taggings
                                         ON taggings.taggable_id = articles.id
                                           AND taggable_type = 'Article'",
                                       "INNER JOIN tags
                                         ON taggings.tag_id = tags.id",
                                       "LEFT OUTER JOIN follows AS followed_tags
                                         ON tags.id = followed_tags.followable_id
                                           AND followed_tags.followable_type = 'ActsAsTaggableOn::Tag'
                                           AND followed_tags.follower_type = 'User'
                                           AND followed_tags.follower_id = :user_id
                                           AND followed_tags.explicit_points >= 0"])

      relevancy_lever(:privileged_user_reaction,
                      label: "-1 when privileged user reactions down-vote, 0 when netural, and 1 when positive.",
                      user_required: false,
                      select_fragment: "(CASE
                 WHEN articles.privileged_users_reaction_points_sum < :negative_reaction_threshold THEN -1
                 WHEN articles.privileged_users_reaction_points_sum > :positive_reaction_threshold THEN 1
                 ELSE 0 END)",
                      group_by_fragment: "articles.privileged_users_reaction_points_sum")

      relevancy_lever(:public_reactions,
                      label: "Weight to give for the number of unicorn, heart, reading list reactions for article.",
                      user_required: false,
                      select_fragment: "articles.public_reactions_count",
                      group_by_fragment: "articles.public_reactions_count")
    end
    private_constant :LEVER_CATALOG
    # rubocop:enable Metrics/BlockLength
  end
end
