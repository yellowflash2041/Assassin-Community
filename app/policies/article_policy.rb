class ArticlePolicy < ApplicationPolicy
  # @return [TrueClass] when only Forem admins can post an Article.
  # @return [FalseClass] when most any Forem user can post an Article.
  #
  # @note This is for Authorization System: use case 1-1.  At present, this is the quickest way to
  #       refactor our code to deliver on that feature.
  #
  # @see https://github.com/forem/forem/pull/16437 for pattern of adding a predicate method to the
  #      "most relevant" class.
  # @see https://github.com/orgs/forem/projects/46 for project details
  def self.limit_post_creation_to_admins?
    FeatureFlag.enabled?(:limit_post_creation_to_admins)
  end

  # @note [@jeremyf] I am re-implemnenting the initialize method, but removing the Pundit
  #       authorization.  There's an assumption that all policy questions will require a user,
  #       unless you know specifically that they don't.
  #
  # @note as a reminder, if you attempt to authorize this policy in a controller with that calls
  #       {CachingHeaders#set_cache_control_headers} you may encounter some headaches.  What do
  #       those headaches look like?  When you call {CachingHeaders#set_cache_control_headers}, you
  #       are likely disallowing checks on current_user (via {EdgeCacheSafetyCheck#current_user}).
  #
  # @todo [@jeremyf] I don't like altering the initializer and its core assumption.  But the other
  #       option to get Articles working for https://github.com/forem/forem/issues/16529 is to
  #       address the at present fundamental assumption regarding "Policies are for authorizing when
  #       you have a user, otherwise let the controller decide."
  #
  # rubocop:disable Lint/MissingSuper
  #
  # @see even Rubocop thinks this is a bad idea.  But the short-cut gets me unstuck.  I hope there's
  #      enough breadcrumbs to undo this short-cut.
  def initialize(user, record)
    @user = user
    @record = record
  end
  # rubocop:enable Lint/MissingSuper

  def feed?
    true
  end

  def create?
    require_user_in_good_standing!
    return true unless self.class.limit_post_creation_to_admins?

    user_any_admin?
  end

  def update?
    require_user_in_good_standing!

    user_author? || user_super_admin? || user_org_admin? || user_any_admin?
  end

  def stats?
    require_user!
    user_author? || user_super_admin? || user_org_admin?
  end

  def subscriptions?
    require_user!
    user_author? || user_super_admin?
  end

  def admin_unpublish?
    require_user!
    user_any_admin?
  end

  def destroy?
    require_user!

    user_author? || user_super_admin? || user_org_admin? || user_any_admin?
  end

  alias admin_featured_toggle? admin_unpublish?

  alias new? create?

  alias delete_confirm? destroy?

  alias discussion_lock_confirm? destroy?

  alias discussion_unlock_confirm? destroy?

  alias edit? update?

  # [@jeremyf] I made a decision to compress preview? into create?  However, someone editing a post
  # should also be able to preview?  Perhaps it would make sense to be "preview? is create? ||
  # update?".
  alias preview? create?

  def permitted_attributes
    %i[title body_html body_markdown main_image published canonical_url
       description tag_list publish_under_org
       video video_code video_source_url video_thumbnail_url receive_notifications
       archived]
  end

  private

  def require_user_in_good_standing!
    require_user!

    return true unless user.suspended?

    raise ApplicationPolicy::UserSuspendedError, I18n.t("policies.application_policy.your_account_is_suspended")
  end

  def require_user!
    return true if user

    raise ApplicationPolicy::UserRequiredError, I18n.t("policies.application_policy.you_must_be_logged_in")
  end

  def user_author?
    if record.instance_of?(Article)
      record.user_id == user.id
    else
      record.pluck(:user_id).uniq == [user.id]
    end
  end

  def user_org_admin?
    user.org_admin?(record.organization_id)
  end
end
