class UserStates
  attr_accessor :user

  def initialize(user)
    @user = user
  end

  def cached_onboarding_checklist
    Rails.cache.fetch("user-#{user.id}-#{user.updated_at}-#{user.comments_count}-#{user.articles_count}-#{user.reactions_count}/onboarding_checklist", expires_in: 100.hours) do
      {
        write_your_first_article: made_first_article,
        follow_your_first_tag: follows_a_tag,
        fill_out_your_profile: fill_out_your_profile,
        leave_your_first_reaction: leave_reactions,
        follow_your_first_dev: follow_people,
        leave_your_first_comment: leave_comments
      }
    end
  end

  def made_first_article
    user.articles.published.any?
  end

  def follows_a_tag
    user.follows.where(followable_type: "ActsAsTaggableOn::Tag").any?
  end

  def fill_out_your_profile
    user.summary.present?
  end

  def leave_reactions
    user.reactions.any?
  end

  def follow_people
    user.follows.where(followable_type: "User").any?
  end

  def leave_comments
    user.comments.any?
  end
end
